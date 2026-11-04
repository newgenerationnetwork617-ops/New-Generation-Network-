#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/bible/books"
BASE="https://raw.githubusercontent.com/midvash/bible-data/main/versions/en/web/books"

mkdir -p "$OUT"

declare -A books=(
  ["Genesis"]="Gen" ["Exodus"]="Exod" ["Leviticus"]="Lev" ["Numbers"]="Num"
  ["Deuteronomy"]="Deut" ["Joshua"]="Josh" ["Judges"]="Judg" ["Ruth"]="Ruth"
  ["1 Samuel"]="1Sam" ["2 Samuel"]="2Sam" ["1 Kings"]="1Kgs" ["2 Kings"]="2Kgs"
  ["1 Chronicles"]="1Chr" ["2 Chronicles"]="2Chr" ["Ezra"]="Ezra" ["Nehemiah"]="Neh"
  ["Esther"]="Esth" ["Job"]="Job" ["Psalms"]="Ps" ["Proverbs"]="Prov"
  ["Ecclesiastes"]="Eccl" ["Song of Solomon"]="Song" ["Isaiah"]="Isa"
  ["Jeremiah"]="Jer" ["Lamentations"]="Lam" ["Ezekiel"]="Ezek" ["Daniel"]="Dan"
  ["Hosea"]="Hos" ["Joel"]="Joel" ["Amos"]="Amos" ["Obadiah"]="Obad"
  ["Jonah"]="Jonah" ["Micah"]="Mic" ["Nahum"]="Nah" ["Habakkuk"]="Hab"
  ["Zephaniah"]="Zeph" ["Haggai"]="Hag" ["Zechariah"]="Zech" ["Malachi"]="Mal"
  ["Matthew"]="Matt" ["Mark"]="Mark" ["Luke"]="Luke" ["John"]="John" ["Acts"]="Acts"
  ["Romans"]="Rom" ["1 Corinthians"]="1Cor" ["2 Corinthians"]="2Cor"
  ["Galatians"]="Gal" ["Ephesians"]="Eph" ["Philippians"]="Phil"
  ["Colossians"]="Col" ["1 Thessalonians"]="1Thess" ["2 Thessalonians"]="2Thess"
  ["1 Timothy"]="1Tim" ["2 Timothy"]="2Tim" ["Titus"]="Titus" ["Philemon"]="Phlm"
  ["Hebrews"]="Heb" ["James"]="Jas" ["1 Peter"]="1Pet" ["2 Peter"]="2Pet"
  ["1 John"]="1John" ["2 John"]="2John" ["3 John"]="3John" ["Jude"]="Jude"
  ["Revelation"]="Rev"
)

for book in "${!books[@]}"; do
  osis="${books[$book]}"
  echo "Preparing $book..."
  curl --fail --silent --show-error --location \
    --retry 6 --retry-all-errors --retry-delay 3 --connect-timeout 20 \
    "$BASE/$osis.json" \
    --output "$OUT/$book.json"
  test -s "$OUT/$book.json" || {
    echo "Downloaded Bible data for $book is empty." >&2
    exit 1
  }
done

echo "Offline Bible data prepared: ${#books[@]} books."