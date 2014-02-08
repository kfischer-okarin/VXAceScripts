#==============================================================================
# 
# "Hide Key Item Quantities"
# Version 1.2
# Last Update: November 25th, 2013
# Author: DerTraveler (dertraveler [at] gmail.com)
#
# Requires: nothing
#
#==============================================================================
#
# Description:
#
# Hides the quantity of Key Items, which are usually unique items.
# It is possible to switch between two modes for Key Items that are possessed
# multiple times: 
#   - Show the quantity as usual
#   - Give each single instance its own item menu entry.
# 
# The changes of the script apply both to the normal menu and to the "Select
# Key Item..." event command.
#
# In addition to the key items you can also make particular normal items (for
# example special weapons or armors) unique, so their quantity will be hidden
# in the item menu.
#
# Just enter the <unique> notetag into the notebox of the item in question.
#
#==============================================================================
#
# How to use:
# 
# Just paste it anywhere in the Materials section and set the display mode
# below in the options
#
#==============================================================================
#
# Changelog:
#
#   1.2:
#     - Major Bugfix: Game doesn't crash anymore with weapons and armors
#   1.1:
#     - Particular items can now be made unique via notetag.
#
#==============================================================================
#
# Terms of use:
#
# - Free to use in any commercial or non-commercial project.
# - Please mail me if you find bugs so I can fix them.
# - If you have feature requests, please also mail me, but I can't guarantee
#   that I will add every requested feature.
# - You don't need to credit me, if you don't want to for some reason, since
#   it's only a bugfix of a standard RPG Maker behaviour.
# - Credit DerTraveler in your project.
#
#==============================================================================

###############################################################################
# OPTIONS
###############################################################################
module HideKeyItemQuantities
  
  #---------------------------------------------------------------------------
  # MULTIPLE_MENU_ENTRIES
  # Set this to true, if key items that are possessed multiple times should
  # each get their own menu entry. Otherwise the standard display of quantity
  # is used.
  #---------------------------------------------------------------------------
  MULTIPLE_MENU_ENTRIES = true
  
end


class Window_ItemList < Window_Selectable

  UNIQUE_NOTETAG = "<unique>"
  
  def is_unique?(item)
    item.note.include?(UNIQUE_NOTETAG) ||
    item.class == RPG::Item && item.key_item?
  end
  
  #-----------------------------------------------
  # alias method: make_item_list
  #-----------------------------------------------
  alias hkiq_make_item_list make_item_list
  def make_item_list
    if HideKeyItemQuantities::MULTIPLE_MENU_ENTRIES
      @data = []
      $game_party.all_items.each { |item| 
        if include?(item)
          if is_unique?(item)
            (1..$game_party.item_number(item)).each { |i| @data << item } 
          else
            @data << item
          end
        end
      }
      @data << nil if include?(nil)
    else
      hkiq_make_item_list
    end
  end
  
  #-----------------------------------------------
  # overwrite method : draw_item_number
  #-----------------------------------------------
  def draw_item_number(rect, item)
    if !(is_unique?(item)) ||
       (!HideKeyItemQuantities::MULTIPLE_MENU_ENTRIES &&
        $game_party.item_number(item) > 1)
      draw_text(rect, sprintf(":%2d", $game_party.item_number(item)), 2)
    end
  end

end