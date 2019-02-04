require_relative '../Language File System - Core.rb'

RSpec.describe LanguageFileSystem do
  let(:default_language) { nil }

  def set_language_to(value)
    LanguageFileSystem.instance_variable_set(:@language, value)
  end

  before do
    # Simulate module load
    stub_const('LanguageFileSystem::DEFAULT_LANGUAGE', default_language)
    set_language_to LanguageFileSystem::DEFAULT_LANGUAGE
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

  def touch(filename)
    open(filename, 'w') do |f|
      f.write ''
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

    describe 'Load language files' do
      include FakeFS::SpecHelpers
      include_context 'With Game.ini'

      let(:language) { :German }

      before do
        set_language_to language
      end

      context 'When encryption is enabled' do
        before do
          stub_const('LanguageFileSystem::ENABLE_ENCRYPTION', true)
        end

        describe 'Dialogue file' do
          let(:rvtext_file) { 'DialoguesGerman.rvtext' }
          let(:filename) { 'Data/DialoguesGerman.rvdata2' }

          context 'When the rvtext file exists' do
            before do
              touch rvtext_file
            end

            it 'loads the encrypted file' do
              expect(LanguageFileSystem).to receive(:load_data).with filename
              initialize_plugin
            end
          end
        end

        describe 'Database text file' do
          let(:rvtext_file) { 'DatabaseTextGerman.rvtext' }
          let(:filename) { 'Data/DatabaseTextGerman.rvdata2' }

          context 'When the rvtext file exists' do
            before do
              touch rvtext_file
            end

            it 'loads the encrypted file and initializes the database' do
              expect(LanguageFileSystem).to receive(:load_data).with filename
              expect(LanguageFileSystem).to receive(:redefine_constants)
              expect(LanguageFileSystem).to receive(:redefine_assignments)
              initialize_plugin
            end
          end
        end
      end

      context 'When encryption is disabled' do
        before do
          stub_const('LanguageFileSystem::ENABLE_ENCRYPTION', false)
        end

        describe 'Dialogue file' do
          let(:filename) { 'DialoguesGerman.rvtext' }

          context 'When the rvtext file exists' do
            before do
              touch filename
            end

            it 'loads the rvtext file' do
              expect(LanguageFileSystem).to receive(:load_dialogues).with language
              initialize_plugin
            end
          end
        end

        describe 'Database text file' do
          let(:filename) { 'DatabaseTextGerman.rvtext' }

          context 'When the rvtext file exists' do
            before do
              touch filename
            end

            it 'loads the rvtext file and initializes the database' do
              expect(LanguageFileSystem).to receive(:load_database).with language
              expect(LanguageFileSystem).to receive(:redefine_constants)
              expect(LanguageFileSystem).to receive(:redefine_assignments)
              initialize_plugin
            end
          end
        end
      end
    end
  end
end
