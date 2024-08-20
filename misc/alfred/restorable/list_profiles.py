import os
import sys
import json

# parse args for
# --action save|resume|delete
# --query <name>
action = None
alfred_query = None
for i, arg in enumerate(sys.argv):
    if arg == '--action':
        action = sys.argv[i + 1]
    if arg == '--query':
        alfred_query = sys.argv[i + 1].strip()
    # let it error if not passing valid args/values as each --flag value combo expects a value

items = []
profiles_dir = os.path.expanduser("~/.config/restorable-profiles")
for profile in os.listdir(profiles_dir):

    profile_path = os.path.join(profiles_dir, profile)

    filename_without_ext = os.path.splitext(profile)[0]

    if not os.path.isdir(profile_path):
        profile_item = {
            "uid": filename_without_ext,
            "title": filename_without_ext,
            "subtitle": f"{action.upper()} profile {filename_without_ext}",
            "arg": filename_without_ext,
            "autocomplete": filename_without_ext,
            "icon": {
                "type": "fileicon",
                "path": profile_path  # todo use smth better than the file icon but for now folder is different and stands out so use that for new and this for existing
            }
        }
        items.append(profile_item)

import os

my_path = os.path.abspath(os.path.dirname(__file__))
static_dir = os.path.join(my_path, 'static')
# look for any *-resume.applescript files and add them to the list
for resume_script in os.listdir(static_dir):
    if not resume_script.endswith('-resume.applescript'):
        continue

    resume_script_path = os.path.join(static_dir, resume_script)
    filename_without_ext = os.path.splitext(resume_script)[0]
    profile_name = filename_without_ext.replace('-resume', '')

    # dont duplicate item in results, if already in list from urls match above
    if any(item['uid'] == profile_name for item in items):
        continue

    resume_item = {
        "uid": profile_name,
        "title": profile_name,
        "subtitle": f"{action.upper()} profile {profile_name}",
        "arg": profile_name,
        "autocomplete": profile_name,
        "icon": {"type": "fileicon", "path": resume_script_path}
    }
    items.append(resume_item)

# add new item if no matches, only intended for saving a new profile
if action == "save":
    items.append({
        "uid": alfred_query,
        "title": "Save '{}'".format(alfred_query),
        "subtitle": "Create a new profile named '{}'".format(alfred_query),
        "arg": alfred_query,
        "autocomplete": alfred_query,
        "icon": {
            "type": "fileicon",
            "path": profiles_dir
        }
    })

# filter items by query (if passed), should I just have alfred do this (via checkbox in filter settings)?
if alfred_query != '':
    items = [item for item in items if alfred_query.lower() in item['title'].lower()]

print(json.dumps({"items": items}))
