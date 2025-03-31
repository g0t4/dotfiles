from IPython.core.ultratb import VerboseTB

# dump all color related settings for VerboseTB (IIGC TB=traceback)
for a in dir(VerboseTB):
    print(a)

#%%

# VerboseTB.tb_highlight = "bg:ansiyellow"  # this is default
print(VerboseTB.tb_highlight)
VerboseTB.tb_highlight = "bg:ansiyellow ansiblack"  # I like the yellow, just want black text
#  PUT THIS IN ipython_config.py when you're happy with it

# other settings, might be related or desirable to change
print(VerboseTB.tb_highlight_style)
print(VerboseTB.tb_offset)

#%%

# EXAMPLE, each func in stack is highlighted (by default) with bg:ansiyellow... with white text
#   run the following and make sure the output is legible
# isb - run just this cell to see defaults/current config

def another_layer():

    def nested_try():
        raise ValueError("Innermost error")

    nested_try()


another_layer()
