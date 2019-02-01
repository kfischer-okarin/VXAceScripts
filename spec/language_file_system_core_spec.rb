require_relative '../Language File System - Core.rb'

RSpec.describe LanguageFileSystem do
  let(:default_language) { nil }

  before do
    # Simulate module load
    stub_const('LanguageFileSystem::DEFAULT_LANGUAGE', default_language)
    LanguageFileSystem.instance_variable_set(:@language, LanguageFileSystem::DEFAULT_LANGUAGE)
  end

  shared_context 'With Game.ini' do
    let(:append_to_game_ini) { nil }

    before do
      open('Game.ini', 'w') do |f|
        f.write "[Game]\n"\
                "RTP=RPGVXAce\n"\
                "Library=System\\RGSS300.dll\n"\
                "Scripts=Data\\Scripts.rvdata2\n"\
                'Title=Unterwegs in Osaka'
        f.write "\n#{append_to_game_ini}" unless append_to_game_ini.nil?
      end
    end
  end

  describe 'Initialization' do
    def initialize_plugin
      DataManager.load_database
    end

    describe 'Initial language' do
      include FakeFS::SpecHelpers

      subject(:initial_language) { LanguageFileSystem.language }

      let(:default_language) { :English }

      context 'No language is set in Game.ini' do
        include_context 'With Game.ini'

        it 'uses the default language' do
          initialize_plugin
          expect(initial_language).to eq default_language
        end
      end

      context 'Language is set in Game.ini' do
        include_context 'With Game.ini' do
          let(:append_to_game_ini) { 'Language=German' }
        end

        it 'uses the set language' do
          initialize_plugin
          expect(initial_language).to eq :German
        end
      end
    end
  end
end
