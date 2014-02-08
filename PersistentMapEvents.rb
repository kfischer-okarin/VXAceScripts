#==============================================================================
# 
# "Persistent Map Events"
# Version 2.0
# Last Update: September 9th, 2013
# Author: DerTraveler (dertraveler [at] gmail.com)
#
#==============================================================================
#
# Description:
#
# Adds the possibility to make map events persistent between map and/or page
# changes. That means that you can leave a map (change a page) and when you 
# return it will be in the exact same state as last time.
# This includes following properties: 
#  - position
#  - direction
#  - position in the current move route
#  - changes to the events appearance by the "Set Move Route..." command
#  - changes to the movement style (speed, frequency) by the "Set Move Route..."
#    command
#  - execution progress of parallel events
#
# It is also possible to only make some of these properties persistents by
# using notetags on event pages.
#
# NOTE #1: Autostart events are NEVER saved.
#
# NOTE #2: All the changes are also included in your save files. Thus, old save
#          files probably won't be compatible anymore.
#
# NOTE #3: Even though I don't think that this will be any problem with today's
#          hardware, you should note that the event data of potentially every
#          map event the player has met is stored in memory and in your save
#          files. If you have exceptionally many events in your game, this could
#          become a problem.
#
#==============================================================================
#
# How to use:
# 
# Paste it anywhere in the Materials section.
# Be sure to set the default behaviour in the options section.
#
#------------------------------------------------------------------------------
# Feature: Set persistence of single events pages with comment notetags
#------------------------------------------------------------------------------
# If you want to overwrite the standard persistence behaviour of a particular
# event page, just add one or more of the following notetags into a Comment-Box.
#
#   <persistence [on/off]> 
#     Activates or deactivates the persistence of this event. If activated the
#     behaviour is as defined in the standard behaviour configuration.
#
#   <persistent [property 1] ([property 2]...)>
#     Saves the given properties in addition to the basic behaviour (either
#     given by configuration or by the persistence-notetag)
#
#   <transient [property 1] ([property 2]...)>
#     Prevents the given properties from being saved. 
#     This modifies the basic behaviour given by configuration or by the 
#     persistence-notetag.
#     This also overrides the properties given in a persistent-notetag.
#
#   List of properties:
#     position    - the event position (map change only)
#     direction   - the event direction
#     move_route  - the execution state of the move route
#     appearance  - includes event graphic, transparent flag, opacity and
#                   blending mode
#     move_style  - includes move speed, move frequency, walking animation flag,
#                   stepping animation flag, direction fix flag, through flag
#     interpreter - the current execution progress of a parallel process event
#     erase       - the erase flag
#     all         - all of the above. 
#                   overwrites all other given properties in the notetag.
#                   
#
#==============================================================================
#
# Changelog:
#   2.0:
#     - Major rewriting of the script. Added support for page changes. Now the 
#       state of every page is saved separately and will be restored
#       accordingly.
#     - Added own notetag code, so the dependency on EST Notetag Grabber was
#       removed
#     - Added more notetags, so that only particular properties will be saved
#
#==============================================================================
#
# Terms of use:
#
# - Free to use in any non-commercial project. For use in commercial projects
#   please mail me.
# - Please mail me if you find bugs so I can fix them.
# - If you have feature requests, please also mail me, but I can't guarantee
#   that I will add every requested feature.
# - Credit DerTraveler in your project.
#
#==============================================================================

###############################################################################
# OPTIONS
###############################################################################
module PersistentMapEvents
  
  CONFIG = {}
  #---------------------------------------------------------------------------
  # GLOBAL_PERSISTENCE
  # Set this to true, if every map event should be persistent by default.
  #---------------------------------------------------------------------------
  CONFIG[:GLOBAL_PERSISTENCE] = false
  #---------------------------------------------------------------------------
  # PERSISTENT_PROPERTIES
  # The list of properties that should be saved by default.
  # This list applies when GLOBAL_PERSISTENCE is true and when the notetag 
  # <persistence on> is used.
  #---------------------------------------------------------------------------
  CONFIG[:PERSISTENT_PROPERTIES] = [:position, :direction, :move_route,
                                    :appearance, :move_style, :interpreter]
  
end

###############################################################################
#
# Do not edit past this point, if you have no idea, what you're doing ;)
#
###############################################################################

module NotetagSupport
  
  def any_notetag?
    !notetags.empty?
  end
  
  def have_notetag?(name, *args)
    notetags.keys.include?(name) &&
    (args.empty? || args == notetags[name])
  end
  
  def any_notetag_from?(names)
    notetags.keys.any? { |k| names.include?(k) }
  end
  
  def notetags
    result = {}
    note.scan(/<([^>]+)>/) { |match|
      args = match[0].split
      result[args[0]] = args[1..-1]
    }
    result
  end
  
end

class Game_Event < Game_Character
  
  include NotetagSupport
  
  #-----------------------------------------------
  # new method : note
  #-----------------------------------------------
  def note
    return "" if !@page
    all_comments = ""
    @list.each { |command|
      if command.code == 108 || command.code == 408
        all_comments += command.parameters[0] + "\n"
      end
    }
    return all_comments
  end

end

#==============================================================================
# Game_System
#==============================================================================
class Game_System

  attr_accessor :saved_events
  
  #-----------------------------------------------
  # alias method : initialize
  #-----------------------------------------------  
  alias pme_initialize initialize
  def initialize
    pme_initialize
    @saved_events = {}
  end
  
end

#==============================================================================
# Game_Event
#==============================================================================
class Game_Event < Game_Character
  
  ALL_PROPERTIES = [:position, :direction, :move_route, :appearance,
                    :move_style, :interpreter, :erase]
  
  attr_accessor :persistent_properties
  
  #-----------------------------------------------
  # overwrite method : clone
  #-----------------------------------------------
  def clone
    result = super()
    result.instance_variable_set("@interpreter", 
                                 @interpreter.clone) if @interpreter
    result
  end
  
  #-----------------------------------------------
  # new method : page_id
  #-----------------------------------------------
  def page_id
    @event.pages.index(@page)
  end
  
  #-----------------------------------------------
  # new method : save_state
  #-----------------------------------------------
  def save_state
    @persistent_properties = determine_persistent_properties
    $game_system.saved_events[[@map_id, @id]] = page_id
    $game_system.saved_events[[@map_id, @id, page_id]] = self.clone
  end
  
  #-----------------------------------------------
  # new method : get_saved_state
  #-----------------------------------------------
  def get_saved_state
    pid = $game_system.saved_events[[@map_id, @id]]
    $game_system.saved_events[[@map_id, @id, pid]]
  end
  
  #-----------------------------------------------
  # new method : get_saved_page
  #-----------------------------------------------
  def get_saved_page
    $game_system.saved_events[[@map_id, @id, page_id]]
  end
  
  #-----------------------------------------------
  # new method : has_saved_state?
  #-----------------------------------------------
  def has_saved_state?
    $game_system.saved_events.has_key?([@map_id, @id])
  end
  
  #-----------------------------------------------
  # new method : has_saved_page?
  #-----------------------------------------------
  def has_saved_page?
    $game_system.saved_events.has_key?([@map_id, @id, page_id])
  end
  
  #-----------------------------------------------
  # new method : persistent?
  #-----------------------------------------------
  def persistent?(property)
    @persistent_properties.include?(property)
  end
  
  def determine_persistent_properties
    transient = have_notetag?("transient") ? 
                notetags["transient"].map { |p| p.to_sym } : []
    return [] if transient.include?(:all)

    standard = Array.new(PersistentMapEvents::CONFIG[:PERSISTENT_PROPERTIES])
    persistent = have_notetag?("persistent") ? 
                 notetags["persistent"].map { |p| p.to_sym } : []
    
    if persistent.include?(:all)
      result = Array.new(ALL_PROPERTIES)
    else
      result = ( PersistentMapEvents::CONFIG[:GLOBAL_PERSISTENCE] && 
                 !have_notetag?("persistence", "off") ) || 
               have_notetag?("persistence", "on") ? standard : []
      result += persistent
      result.uniq!
    end
    
    return result - transient
  end
  
  def restore_event
    restored = get_saved_state
    
    @persistent_properties = restored.persistent_properties
    
    if persistent?(:position)
      @x = restored.x
      @y = restored.y
      @real_x = x
      @real_y = y
      @bush_depth = restored.bush_depth
    end
    
    if persistent?(:direction)
      @direction = restored.direction
    end
    
    if persistent?(:appearance)
      @tile_id = restored.tile_id
      @character_name = restored.character_name
      @character_index = restored.character_index
      @opacity = restored.opacity
      @blend_type = restored.blend_type
      @transparent = restored.transparent
    end
    
    if persistent?(:move_style)
      @move_speed = restored.move_speed
      @move_frequency = restored.move_frequency
      @walk_anime = restored.walk_anime
      @step_anime = restored.step_anime
      @direction_fix = restored.direction_fix
      @through = restored.through
    end
    
    if persistent?(:move_route)
      @move_route_forcing = restored.move_route_forcing
      @pattern = restored.pattern
      @anime_count = restored.instance_variable_get("@anime_count")
      @stop_count = restored.instance_variable_get("@stop_count")
      @jump_count = restored.instance_variable_get("@jump_count")
      @jump_peak = restored.instance_variable_get("@jump_peak")
      @move_route = restored.instance_variable_get("@move_route")
      @move_route_index = restored.instance_variable_get("@move_route_index")
      @original_move_route = restored.instance_variable_get("@original_move_route")
      @original_move_route_index = restored.instance_variable_get("@original_move_route_index")
      @wait_count = restored.instance_variable_get("@wait_count")
      @move_succeed = restored.instance_variable_get("@move_succeed")
    end
    
    if persistent?(:erase)
      @erased = restored.instance_variable_get("@erased")
    end
    
    refresh
  end
  
  def restore_page
    restored = get_saved_page
    
    @persistent_properties = restored.persistent_properties
    
    if persistent?(:direction)
      @direction          = restored.direction
    end
    
    if persistent?(:appearance)
      @tile_id            = restored.tile_id
      @character_name     = restored.character_name
      @character_index    = restored.character_index
    end
    
    if persistent?(:move_style)
      @move_speed         = restored.move_speed
      @move_frequency     = restored.move_frequency
      @walk_anime         = restored.walk_anime
      @step_anime         = restored.step_anime
      @direction_fix      = restored.direction_fix
      @through            = restored.through
    end
    
    if persistent?(:move_route)
      @pattern            = restored.pattern
      @move_route_forcing = restored.move_route_forcing
      @move_route         = restored.instance_variable_get("@move_route")
      @move_route_index   = restored.instance_variable_get("@move_route_index")
      @original_move_route = restored.instance_variable_get("@original_move_route")
      @original_move_route_index = restored.instance_variable_get("@original_move_route_index")
      @wait_count = restored.instance_variable_get("@wait_count")
    end
    
    if persistent?(:interpreter)
      @interpreter        = restored.instance_variable_get("@interpreter")
      @interpreter.create_fiber if @interpreter
    end
    
    @original_direction = @page.graphic.direction    
    @original_pattern   = @page.graphic.pattern
  end
  
  #-----------------------------------------------
  # alias method : initialize
  #-----------------------------------------------
  alias pme_initialize initialize
  def initialize(map_id, event)
    pme_initialize(map_id, event)
    @persistent_properties = []
    
    restore_event if has_saved_state?
  end
  
  #-----------------------------------------------
  # alias method : setup_page
  #-----------------------------------------------
  alias pme_setup_page setup_page
  def setup_page(new_page)
    save_state if @page
    
    pme_setup_page(new_page)
  end
  
  #-----------------------------------------------
  # alias method : setup_page_settings
  #-----------------------------------------------
  alias pme_setup_page_settings setup_page_settings
  def setup_page_settings
    pme_setup_page_settings
    
    restore_page if has_saved_page?
  end
  
end

#==============================================================================
# Game_Player
#==============================================================================
class Game_Player < Game_Character

  #-----------------------------------------------
  # alias method : perform_transfer
  #-----------------------------------------------
  alias pme_perform_transfer perform_transfer
  def perform_transfer
    if transfer?
      $game_map.events.each { |id, event|
        event.save_state
      }
    end
    pme_perform_transfer
  end

end