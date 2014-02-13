#==============================================================================
# 
# Language File System - Text Viewer
# Version 1.0
# Last Update: September 28th, 2013
# Author: DerTraveler (dertraveler [at] gmail.com)
#
# Requirements: Language File System - Core Script
#
#==============================================================================

$imported = {} if $imported.nil?
$imported[:LanguageFileSystem_TextViewer] = true

#==============================================================================
#
# Description:
#
# This script adds an debug text viewer for the external language files menu to
# the Test Play Mode of your game. This enables you to quickly check how a newly
# added message or choice will look ingame.
#
#==============================================================================
#
# How to Use:
# 
# Just paste the script into the Materials section somewhere below the Language
# File System Core Script. If the core script is not installed or below this
# script, this script will no nothing.
#
# While in Debug Mode following features are available:
#
#   Text Viewer
#     You can open up the text viewer with a press to F8 while being on a map.
#     If your text IDs contain '/' characters, these will be interpreted as
#     directory names and will be displayed in the text viewer correspondingly.
#     Apart from enabling a more convenient way of browsing your text elements
#     this naming convention has no effect.
#
#   Reload Language Files
#     You can also press F5 anytime on a map or in the text viewer to reload the
#     current language files (in most cases to do a quick review of a changed
#     message).
#
# You can change these hotkeys in the options below, if you don't like them.
#
# This script doesn't affect the functionality of the core script and you can
# delete it from your project when distributing your game.
#
#==============================================================================
#
# Terms of use:
#
# - Free to use in any non-commercial or commercial project since it is only an
#   debug tool to support the use of the core script ;). For the use of the
#   core script in commercial projects please mail me.
# - Please mail me if you find bugs so I can fix them.
# - If you have feature requests, please also mail me, but I can't guarantee
#   that I will add every requested feature.
# - Credit DerTraveler in your project.
#
#==============================================================================

if $imported[:LanguageFileSystem_Core]
  
module LanguageFileSystem

  module TextViewer
    
    #--------------------------------------------------------------------------
    # TEXT_VIEWER_KEY
    # Key that has to be pressed in order to start the text viewer
    #--------------------------------------------------------------------------
    TEXT_VIEWER_KEY = :F8
    #--------------------------------------------------------------------------
    # RELOAD_KEY
    # Key that has to be pressed in order to reload the language files for the
    # current language
    #--------------------------------------------------------------------------
    RELOAD_KEY = :F5
    
  end

end
###############################################################################
#
# Do not edit past this point, if you have no idea, what you're doing ;)
#
###############################################################################

#==============================================================================
# ** Scene_Map
#------------------------------------------------------------------------------
# Adds the hotkey support for accessing the text viewer.
#
# Changes:
#   alias: update_scene
#   new methods: update_call_textviewer, update_reload_languagefiles
#==============================================================================
class Scene_Map < Scene_Base
  
  alias lfs_update_scene update_scene
  def update_scene
    lfs_update_scene
    update_call_textviewer unless scene_changing?
    update_reload_languagefiles unless scene_changing?
  end
  
  def update_call_textviewer
    SceneManager.call(Scene_TextViewer) if $TEST && Input.trigger?(
      LanguageFileSystem::TextViewer::TEXT_VIEWER_KEY)
  end
  
  def update_reload_languagefiles
    if $TEST && Input.trigger?(LanguageFileSystem::TextViewer::RELOAD_KEY)
      Sound::play_load
      LanguageFileSystem::initialize
      $game_message.add("Language files reloaded")
    end
  end
  
end

#==============================================================================
# ** Scene_TextViewer (New Class)
#------------------------------------------------------------------------------
# The debug scene.
#==============================================================================
class Scene_TextViewer < Scene_MenuBase

  #--------------------------------------------------------------------------
  # * Create all windows
  #--------------------------------------------------------------------------
  def start
    super
    create_list_window
    create_help_window
    create_message_window
  end
  
  #--------------------------------------------------------------------------
  # * Create help window that shows the current language and path
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new
    refresh_help_window
  end

  #--------------------------------------------------------------------------
  # * Create window that lists all existing text IDs
  #--------------------------------------------------------------------------
  def create_list_window
    @list_window = Window_TextViewer.new(0, 72, Graphics.width, 
                                         Graphics.height - 72)
    @list_window.set_handler(:ok, method(:on_id_ok))
    @list_window.set_handler(:cancel, method(:on_id_cancel))
  end

  #--------------------------------------------------------------------------
  # * Create message window for message preview
  #--------------------------------------------------------------------------
  def create_message_window
    @message_window = Window_Message.new
  end                                    
  
  #--------------------------------------------------------------------------
  # * Refresh help window after pressing OK
  #--------------------------------------------------------------------------
  def on_id_ok
    @list_window.on_ok
    refresh_help_window
  end
  
  #--------------------------------------------------------------------------
  # * Refresh help window after pressing Cancel. 
  #   Exit scene if canceled on top level.
  #--------------------------------------------------------------------------
  def on_id_cancel
    cancel = @list_window.on_cancel
    refresh_help_window
    return_scene if cancel
  end
  
  #--------------------------------------------------------------------------
  # * Set the help window text
  #--------------------------------------------------------------------------
  def refresh_help_window
    display_language = @list_window.language || "Default Language"
    hint = @list_window.language ? " (Press Q or W to switch languages)" : ""
    @help_window.set_text("\\C[6][#{display_language}]\\C[0]#{hint}\n" +
                          "#{@list_window.path}")
  end
  
  #--------------------------------------------------------------------------
  # * Button handlers
  #--------------------------------------------------------------------------
  def update
    super
    update_change_language unless scene_changing? || $game_message.busy?
    update_refresh_textdata unless scene_changing? || $game_message.busy?
  end
  
  #--------------------------------------------------------------------------
  # * Change language on pressing L or R
  #--------------------------------------------------------------------------
  def update_change_language
    if $TEST && (Input.trigger?(:L) || Input.trigger?(:R))
      if LanguageFileSystem::LANGUAGES.empty?
        Sound::play_buzzer
        return
      end
      Sound::play_cursor
      new_index = (LanguageFileSystem::LANGUAGES.index(@list_window.language) +
                   (Input.trigger?(:L) ? -1 : +1)) %
                   LanguageFileSystem::LANGUAGES.length
      @list_window.language = LanguageFileSystem::LANGUAGES[new_index]
      refresh_help_window
    end
  end
  
  #--------------------------------------------------------------------------
  # * Reload current language file on pressing F5
  #--------------------------------------------------------------------------
  def update_refresh_textdata
    if $TEST && Input.trigger?(LanguageFileSystem::TextViewer::RELOAD_KEY)
      Sound::play_load
      LanguageFileSystem::initialize
      @list_window.build
    end
  end
  
end

#==============================================================================
# ** Window_TextViewer (New Class)
#------------------------------------------------------------------------------
# A window that lists all existing text IDs from the language files in a
# hierarchichal manner.
#==============================================================================
class Window_TextViewer < Window_Selectable
  
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :path                     # current path  

  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @data = { nil => [] }
    @path = nil
    @original_language = language
    @wait_for_message = false
    
    build
    
    activate
  end
  
  #--------------------------------------------------------------------------
  # * Get language
  #--------------------------------------------------------------------------
  def language
    LanguageFileSystem::language
  end
  
  #--------------------------------------------------------------------------
  # * Set new language
  #--------------------------------------------------------------------------
  def language=(value)
    LanguageFileSystem::set_language(value)
    build
  end
  
  #--------------------------------------------------------------------------
  # * Switch off standard handling for R
  #--------------------------------------------------------------------------
  def cursor_pagedown; end
  
  #--------------------------------------------------------------------------
  # * Switch off standard handling for L
  #--------------------------------------------------------------------------
  def cursor_pageup; end
  
  #--------------------------------------------------------------------------
  # * Show the selected message or enter directory
  #--------------------------------------------------------------------------
  def on_ok
    if item.end_with?("/")
      @path = @path ? @path + item : item
      refresh
      select(0)
      activate
    else
      LanguageFileSystem::show_dialogue(item)
      @wait_for_message = true
    end
  end
  
  #--------------------------------------------------------------------------
  # * Go to the parent directory if not already at toplevel. Otherwise tell
  #   the Scene to quit.
  #--------------------------------------------------------------------------
  def on_cancel
    unless @path == nil
      oldpath = @path
      @path = @path[0..-2].include?("/") ? 
        @path[0..@path[0..-2].rindex("/")] : nil
      refresh
      select(@data[@path].index(oldpath))
      activate
      return false
    end
    LanguageFileSystem::set_language(@original_language) unless 
      language == @original_language
    return true
  end

  #--------------------------------------------------------------------------
  # * Number of columns
  #--------------------------------------------------------------------------
  def col_max
    return 2
  end

  #--------------------------------------------------------------------------
  # * Maximum number of items
  #--------------------------------------------------------------------------
  def item_max
    @data && @data[@path] ? @data[@path].size : 1
  end

  #--------------------------------------------------------------------------
  # * Currently selected item
  #--------------------------------------------------------------------------
  def item
    index >= 0 ? @data[@path][index] : nil
  end

  #--------------------------------------------------------------------------
  # * Parse the dialogue hash and create directory structure
  #--------------------------------------------------------------------------
  def make_item_list(root = nil)
    items = LanguageFileSystem::dialogues.keys
    items = items.select { |k| k.start_with?(root) } if root
    subcats = items.group_by { |k|
      without_prefix = root ? k[root.length..-1] : k
      without_prefix.include?("/") ? 
      without_prefix[0..without_prefix.index("/")] : nil
    }
    @data[root] = subcats.has_key?(nil) ? subcats.delete(nil).sort : []
    @data[root] = subcats.keys.sort + @data[root]
    subcats.keys.each { |k| make_item_list(root ? root + k : k) }
  end

  #--------------------------------------------------------------------------
  # * Draw text ID as item name
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[@path][index]
    if item
      if item.end_with?("/")
        draw_text(item_rect_for_text(index), item, alignment)
      else
        draw_text(item_rect_for_text(index), 
                  @path ? item[@path.length..-1] : item,
                  alignment)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # * Alignment of the items
  #--------------------------------------------------------------------------
  def alignment
    return 0
  end

  #--------------------------------------------------------------------------
  # * Refresh the window
  #--------------------------------------------------------------------------
  def refresh
    create_contents
    draw_all_items
  end
  
  #--------------------------------------------------------------------------
  # * Rebuild the whole underlying content if the language was changed or the
  #   reload button was pressed.   
  #--------------------------------------------------------------------------
  def build
    old_item = item
    
    @data = { nil => [] }
    make_item_list
    
    if @data.has_key?(@path)
      refresh
      select(@data[@path].index(old_item) || 0)
    else
      @path = nil
      refresh
      select(0)
    end
  end
  
  #--------------------------------------------------------------------------
  # * Return to this window if a message was shown before
  #--------------------------------------------------------------------------
  def update
    super
    if @wait_for_message && !$game_message.busy?
      refresh
      activate
      @wait_for_message = false
    end
  end
end

end