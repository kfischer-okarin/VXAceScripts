module DataManager
  def self.load_database; end
end

class Game_Message
  def add; end

  def clear; end
end

class Game_Interpreter
  def setup_choices; end
end

module Cache
  def self.load_bitmap; end
end

class Game_Actor
  def setup; end
end

module RPG
  class BaseItem
    def name; end

    def description; end

    def note; end
  end
  class UsableItem
  end
  class Actor < BaseItem
    def nickname; end
  end
  class Class
  end
  class Skill < UsableItem
    def message1; end

    def message2; end
  end
  class Item
  end
  class Weapon
  end
  class Armor
  end
  class Enemy
  end
  class State < BaseItem
    def message1; end

    def message2; end

    def message3; end

    def message4; end
  end
  class System
    def game_title; end

    def currency_unit; end

    def elements; end

    def skill_types; end

    def weapon_types; end

    def armor_types; end
  end
  class System::Terms
    def basic; end

    def params; end

    def etypes; end

    def commands; end
  end
  class Map
    def display_name; end

    def note; end
  end
end

# RPG Maker global methods
class Module
  def load_data(path)
  end
end

$imported = nil
