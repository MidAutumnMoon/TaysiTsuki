function __set_tide_variable
    set --function section "$argv[1]"
    set --function item "$argv[2]"
    set --function values $argv[3..-1]
    set --global tide_{"$section"}_{"$item"} $values
end


#
# Prompts
#

__set_tide_variable prompt icon_connection ' '
__set_tide_variable prompt add_newline_before true
__set_tide_variable prompt pad_items false

__set_tide_variable left_prompt frame_enabled false
__set_tide_variable left_prompt items \
    'pwd' 'git' 'jobs' 'newline' 'character'

__set_tide_variable right_prompt frame_enabled false
__set_tide_variable right_prompt items \
    'cmd_duration' 'status' 'private_mode'


#
# Items
#

__set_tide_variable character icon '+'
__set_tide_variable character color '005FD7'
__set_tide_variable character color_failure 'FF0000'

__set_tide_variable cmd_duration threshold '5000'
__set_tide_variable cmd_duration decimals '1'
__set_tide_variable cmd_duration icon ''

__set_tide_variable jobs icon ' jobs'
__set_tide_variable jobs color 'blue'

__set_tide_variable git color_branch 'purple'
__set_tide_variable git icon ''

__set_tide_variable pwd color_anchors '66ccff'
__set_tide_variable pwd color_dirs '289eda'
__set_tide_variable pwd markers \
    '.git' 'README.md' \
    'flake.nix' 'default.nix' \
    'Cargo.toml'

__set_tide_variable private_mode icon ' private'

__set_tide_variable status icon_failure 'X'


#
# Cleanup
#

functions --erase __set_tide_variable
