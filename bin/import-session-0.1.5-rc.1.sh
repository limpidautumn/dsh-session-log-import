#!/usr/bin/env bash
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: ${0##*/} <session-export.zip> <destination-session-dir>" >&2; exit 2; }

ZIP=$1
DEST=$2
[ -f "$ZIP" ] || { echo "no such zip: $ZIP" >&2; exit 1; }

mkdir -p "$(dirname "$DEST")"
DEST=$(cd "$(dirname "$DEST")" && pwd)/$(basename "$DEST")
DSH_HOME=${DSH_HOME:-$HOME/.dsh}
case "$DEST" in
  "$DSH_HOME"/sessions/*) ATTACH_ROOT=$DSH_HOME/attachments ;;
  */sessions/*) ATTACH_ROOT=$(cd "$(dirname "$DEST")" && pwd)/../../attachments ;;
  *) ATTACH_ROOT=$(cd "$(dirname "$DEST")" && pwd)/../attachments ;;
esac

WORK=$(mktemp -d "${TMPDIR:-/tmp}/dsh-import.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
unzip -qq -o "$ZIP" -d "$WORK"

node - "$WORK/session.v3.jsonl" "$DEST" "$ATTACH_ROOT" <<'NODE'
const [logPath, sessionDir, attachmentsRoot] = process.argv.slice(2)
const { chmodSync, copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } = require('node:fs')
const { constants, zstdCompress } = require('node:zlib')
const { createHash } = require('node:crypto')
const { dirname, join } = require('node:path')

const compress = (input) => new Promise((resolve, reject) => {
  zstdCompress(input, { params: { [constants.ZSTD_c_checksumFlag]: 1 } }, (error, result) => error ? reject(error) : resolve(result))
})

const text = readFileSync(logPath, 'utf8')
const lines = text.split('\n')
if (lines[lines.length - 1] === '') lines.pop()
const header = JSON.parse(lines[0])
if (header.type !== 'session' || header.version !== 3) throw new Error('not a v3 session log')
for (let i = 1; i < lines.length; i++) {
  if (JSON.parse(lines[i]).seq !== i - 1) throw new Error(`bad seq at line ${i + 1}`)
}
const events = lines.slice(1)

const referenced = new Set()
const visit = (content) => {
  if (!Array.isArray(content)) return
  for (const value of content) {
    if (typeof value !== 'object' || value === null) continue
    if ((value.type === 'image' || value.type === 'file') && value.attachment) referenced.add(String(value.attachment.attachmentId))
    if (Array.isArray(value.content)) visit(value.content)
  }
}
for (const line of events) {
  const data = JSON.parse(line).data
  if (typeof data !== 'object' || data === null) continue
  visit(data.content)
  visit(data.message?.content)
  if (Array.isArray(data.inserted)) for (const message of data.inserted) visit(message.content)
  if (Array.isArray(data.stream)) for (const record of data.stream) {
    if (record?.type === 'chunk' && record.chunk?.type === 'block-end') visit([record.chunk.block])
  }
}

const main = async () => {
  const frames = [await compress(Buffer.from(`${lines[0]}\n`))]
  if (events.length > 0) frames.push(await compress(Buffer.from(`${events.join('\n')}\n`)))
  mkdirSync(sessionDir, { recursive: true })
  writeFileSync(join(sessionDir, 'session.v3.jsonl.zstd'), Buffer.concat(frames), { mode: 0o600 })
  const lockPath = join(sessionDir, 'session.lock')
  if (!existsSync(lockPath)) writeFileSync(lockPath, '')

  const mediaDir = join(dirname(logPath), 'media')
  let restored = 0
  for (const attachmentId of referenced) {
    const hex = attachmentId.replace(/^sha256:/u, '')
    if (!/^[a-f0-9]{64}$/u.test(hex)) throw new Error(`bad attachment id: ${attachmentId}`)
    const hit = readdirSync(mediaDir).find((name) => name === attachmentId || name.startsWith(`${attachmentId}.`))
    if (hit === undefined) throw new Error(`attachment missing from media/: ${attachmentId}`)
    const data = readFileSync(join(mediaDir, hit))
    if (createHash('sha256').update(data).digest('hex') !== hex) throw new Error(`digest mismatch: ${attachmentId}`)
    const targetDir = join(attachmentsRoot, 'v1', 'objects', hex.slice(0, 2))
    mkdirSync(targetDir, { recursive: true })
    copyFileSync(join(mediaDir, hit), join(targetDir, hex))
    chmodSync(join(targetDir, hex), 0o444)
    restored += 1
  }
  console.log(`${header.id}: ${events.length} events, ${frames.length} frames, ${restored}/${referenced.size} attachments`)
}

main().catch((error) => { console.error(error.message); process.exit(1) })
NODE

ls -l "$DEST"
