set dotenv-load

memos_instance := env('UMCH_USEMEMOS_INSTANCE')
storage := '~/.local/state/umch/' + memos_instance

# this list
default:
  @just --list --unsorted

# setup data directory
setup:
  mkdir -p {{ storage }}/memos
  mkdir -p {{ storage }}/temp

# get info about a memo w/ it's id
get id:
  @xh get https://{{ memos_instance }}/api/v1/memos/{{ id }} \
    "Accept: application/json" \
    "Authorization: Bearer $UMCH_USEMEMOS_TOKEN" | jq '.'

temp_filename := storage + "/temp/" + uuid() + ".md"
# make a new memo, provide path to file for existing file
new *file:
  {{ if file == "" { "touch " + temp_filename + " && $EDITOR " + temp_filename } else { "" } }}
  @xh post https://{{ memos_instance }}/api/v1/memos \
    "Content-Type: text/plain;charset=UTF-8" \
    "Authorization: Bearer $UMCH_USEMEMOS_TOKEN" \
    "content=$(jq -Rsr '.' {{ if file == "" { temp_filename } else { file } }})" | jq -r '.name' | awk '{print "memo created @ https://{{ memos_instance }}/"$1}'

# download a memo w/ it's id, put it in standardized local storage (output path)
dl id:
  @xh get https://{{ memos_instance }}/api/v1/memos/{{ id }} \
    "Accept: application/json" \
    "Authorization: Bearer $UMCH_USEMEMOS_TOKEN" | jq -r '.content' > {{ storage }}/memos/{{ id }}.md
  @echo "downloaded to {{storage}}/memos/{{ id }}.md"

# update a memo from standardized local storage (from dl above)
update id:
  @xh patch https://{{ memos_instance }}/api/v1/memos/{{ id }} \
    "Content-Type: text/plain;charset=UTF-8" \
    "Authorization: Bearer $UMCH_USEMEMOS_TOKEN" \
    "content=$(jq -Rsr '.' {{ storage }}/memos/{{ id }}.md)" \
    "updateTime={{ datetime_utc('%+') }}" \
    | jq -r '.name' | awk '{print "memo updated @ https://{{ memos_instance }}/"$1}'

# list downloaded
ls:
  @ls -1 {{ storage }}/memos | sed -e 's/\..*$//'

# open storage dir
open:
  open {{ storage }}/memos

# edit note from id with $EDITOR
edit id:
  @just dl {{ id }}
  @$EDITOR {{ storage }}/memos/{{ id }}.md
  @just update {{ id }}
