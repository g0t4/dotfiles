import os
import sys
import json

alfred_query = sys.argv[1] if len(sys.argv) > 1 else ''
alfred_query = alfred_query.strip()

## todo what about iterm resume profiles that are just applescripts currently...
#  below I need to find these and use them as names in the list too... could use *-resume.applescript to find profile names to resume (and update brave-resume.applescript to do more than just brave, same with save, OR add a python script to unify resume/save and have it call brave resume/save applescripts)
#  osascript "$WES_DOTFILES/misc/restorable-profiles/iterm-resume.applescript" haskell
#  osascript "$WES_DOTFILES/misc/restorable-profiles/dotfiles-resume.applescript"


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
            "uid": filename_without_ext,
            "title": filename_without_ext,
            "subtitle": filename_without_ext,
            "arg": filename_without_ext,
            "autocomplete": filename_without_ext,
            "icon": {
                "type": "fileicon",
                "path": profile_path # todo use smth better than the file icon but for now folder is different and stands out so use that for new and this for existing
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

    if alfred_query != '' and alfred_query.lower() not in profile_name.lower():
        # skip if query is not in profile name
        continue

    # dont duplicate item in results, if already in list from urls match above
    if any(item['uid'] == profile_name for item in items):
        continue

    resume_item = {
        "uid": profile_name,
        "title": profile_name,
        "subtitle": profile_name,
        "arg": profile_name,
        "autocomplete": profile_name,
        "icon": {
            "type": "fileicon",
            "path": resume_script_path
        }
    }
    items.append(resume_item)

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
