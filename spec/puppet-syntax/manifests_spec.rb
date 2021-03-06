require 'spec_helper'

describe PuppetSyntax::Manifests do
  let(:subject) { PuppetSyntax::Manifests.new }

  it 'should expect an array of files' do
    expect { subject.check(nil) }.to raise_error(/Expected an array of files/)
  end

  it 'should return nothing from a valid file' do
    files = fixture_manifests('pass.pp')
    res = subject.check(files)

    res.should == []
  end

  it 'should return an error from an invalid file' do
    files = fixture_manifests('fail_error.pp')
    res = subject.check(files)

    res.should have(1).items
    res.first.should match(/Syntax error at '\}' .*:3$/)
  end

  it 'should return a warning from an invalid file' do
    files = fixture_manifests('fail_warning.pp')
    res = subject.check(files)

    res.should have(2).items
    res[0].should match(/Unrecognised escape sequence '\\\[' .* at line 3$/)
    res[1].should match(/Unrecognised escape sequence '\\\]' .* at line 3$/)
  end

  it 'should ignore warnings about storeconfigs' do
    files = fixture_manifests('pass_storeconfigs.pp')
    res = subject.check(files)

    res.should == []
  end

  it 'should read more than one valid file' do
    files = fixture_manifests(['pass.pp', 'pass_storeconfigs.pp'])
    res = subject.check(files)

    res.should == []
  end

  it 'should continue after finding an error in the first file' do
    files = fixture_manifests(['fail_error.pp', 'fail_warning.pp'])
    res = subject.check(files)

    res.should have(3).items
    res[0].should match(/Syntax error at '\}' .*:3$/)
    res[1].should match(/Unrecognised escape sequence '\\\[' .* at line 3$/)
    res[2].should match(/Unrecognised escape sequence '\\\]' .* at line 3$/)
  end

  describe 'future_parser' do
    context 'future_parser = false (default)' do
      it 'should fail without setting future option to true on future manifest' do
        PuppetSyntax.future_parser.should == false

        files = fixture_manifests(['future_syntax.pp'])
        res = subject.check(files)

        res.should have(1).items
        res[0].should match(/Syntax error at '='; expected '\}' .*:2$/)
      end
    end

    context 'future_parser = true' do
      before(:each) {
        PuppetSyntax.future_parser = true
      }

      if Puppet::Util::Package.versioncmp(Puppet.version, '3.2') >= 0
        context 'Puppet >= 3.2' do
          it 'should pass with future option set to true on future manifest' do
            files = fixture_manifests(['future_syntax.pp'])
            res = subject.check(files)

            res.should have(0).items
          end
        end
      else
        context 'Puppet <= 3.2' do
          it 'should return an error that the parser option is not supported' do
            files = fixture_manifests(['future_syntax.pp'])
            res = subject.check(files)

            res.should have(1).items
            res[0].should == "Attempt to assign a value to unknown configuration parameter :parser"
          end
        end
      end
    end
  end

end
