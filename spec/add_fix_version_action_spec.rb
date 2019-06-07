describe Fastlane::Actions::AddFixVersionAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The add_fix_version plugin is working!")

      Fastlane::Actions::AddFixVersionAction.run(nil)
    end
  end
end
