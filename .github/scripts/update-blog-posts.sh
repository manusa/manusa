#!/bin/bash
# Updates the README.md with the latest blog posts from the RSS feed

set -e

FEED_URL="https://blog.marcnuri.com/feed.xml"
README_FILE="README.md"
POST_COUNT=3
POSTS_FILE=$(mktemp)

# Fetch feed and extract posts (portable across macOS and Linux)
curl -s "$FEED_URL" | \
  awk -v count="$POST_COUNT" '
    /<item>/ { in_item=1; title=""; link=""; desc="" }
    /<\/item>/ {
      if (in_item && printed < count) {
        print "- [" title "](" link ")"
        print "  " desc
        printed++
      }
      in_item=0
    }
    in_item && /<title>/ {
      gsub(/.*<title>/, "")
      gsub(/<\/title>.*/, "")
      gsub(/<!\[CDATA\[/, "")
      gsub(/\]\]>/, "")
      title=$0
    }
    in_item && /<link>/ {
      gsub(/.*<link>/, "")
      gsub(/<\/link>.*/, "")
      link=$0
    }
    in_item && /<description>/ {
      gsub(/.*<description>/, "")
      gsub(/<\/description>.*/, "")
      gsub(/<!\[CDATA\[/, "")
      gsub(/\]\]>/, "")
      desc=$0
    }
  ' > "$POSTS_FILE"

# Update README using the temp file
awk -v posts_file="$POSTS_FILE" '
  /<!-- BLOG-POST-LIST:START -->/ {
    print
    while ((getline line < posts_file) > 0) print line
    close(posts_file)
    skip=1
    next
  }
  /<!-- BLOG-POST-LIST:END -->/ {
    skip=0
  }
  !skip {print}
' "$README_FILE" > README.tmp && mv README.tmp "$README_FILE"

rm -f "$POSTS_FILE"
echo "Updated $README_FILE with latest blog posts"