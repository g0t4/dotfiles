import os
import sys
import json

alfred_query = sys.argv[1] if len(sys.argv) > 1 else ''
alfred_query = alfred_query.strip()

items = []
profiles_dir = os.path.expanduser("~/.config/restorable-profiles")
for profile in os.listdir(profiles_dir):
    if alfred_query != '' and alfred_query.lower() not in profile.lower():
        # skip if query is not in profile name
        continue

    profile_path = os.path.join(profiles_dir, profile)

    filename_without_ext = os.path.splitext(profile)[0]

    if not os.path.isdir(profile_path):
        profile_item = {
            "uid": profile,
            "title": profile,
            "subtitle": profile_path,
            "arg": filename_without_ext,
            "autocomplete": profile,
            "icon": {
                "type": "fileicon",
                "path": profile_path
            }
        }
        items.append(profile_item)

# add new item if no matches, only intended for saving a new profile... with out this, cannot save a new profile b/c cannot pick a name that doesn't already exist
no_new_profile = '--no-new-profile' in sys.argv
if not no_new_profile:
    items.append({
        "uid": alfred_query,
        "title": "Save a new profile named '{}'".format(alfred_query),
        "arg": alfred_query,
        "autocomplete": alfred_query,
        "icon": {
            "type": "fileicon",
            "path": profiles_dir
        }
    })

print(json.dumps({"items": items}))
