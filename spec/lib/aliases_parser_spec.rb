require 'spec_helper'
require 'tempfile'

describe SugoiAliasesUpdator::AliasesParser do
  let(:source_aliases_flle) {
    tempfile = Tempfile.new('aliases')
    File.write(tempfile.path, source_aliases)
    tempfile
  }
  let(:source_aliases) { <<-ALIASES
MAILER-DAEMON:	postmaster
postmaster:	root

# General redirections for pseudo accounts
bin:		root
daemon:		root
named:		root, n905i.1214@gmail.com
nobody:		root, n905i.1214@gmail.com
uucp:		root
www:		root, n905i.1214@gmail.com, java@java.com
                         ALIASES
  }
  let(:aliases_parser) { SugoiAliasesUpdator::AliasesParser.new(source_aliases_flle.path) }

  after(:each) do
    source_aliases_flle.unlink
  end

  describe '#add' do
    let(:expected) { <<-ALIASES
MAILER-DAEMON:	postmaster
postmaster:	root

# General redirections for pseudo accounts
bin:		root, admin@github.com
daemon:		root
named:		root, n905i.1214@gmail.com
nobody:		root, n905i.1214@gmail.com
uucp:		root
www:		root, n905i.1214@gmail.com, java@java.com, admin@github.com
                     ALIASES
    }
    it 'add target' do
      expect(
        aliases_parser.add('admin@github.com', to: %w(bin www))
      ).to eq expected
    end

    context 'when TO=email' do
      let(:expected) { <<-ALIASES
MAILER-DAEMON:	postmaster
postmaster:	root

# General redirections for pseudo accounts
bin:		root, admin@github.com
daemon:		root
named:		root, n905i.1214@gmail.com
nobody:		root, n905i.1214@gmail.com
uucp:		root
www:		root, n905i.1214@gmail.com, java@java.com, admin@github.com
                       ALIASES
      }

      it '渡されたemailの所属しているlabelを追加すること' do
      end
    end

    context 'when exist email' do
      let(:expected) { <<-ALIASES
MAILER-DAEMON:	postmaster
postmaster:	root

# General redirections for pseudo accounts
bin:		root
daemon:		root
named:		root, n905i.1214@gmail.com
nobody:		root, n905i.1214@gmail.com
uucp:		root
www:		root, n905i.1214@gmail.com, java@java.com
                       ALIASES
      }
      it "don't duplicate" do
        expect(
          aliases_parser.add('n905i.1214@gmail.com', to: %w(named www))
        ).to eq expected
      end
    end
  end

  describe '#rm' do
    let(:expected) { <<-ALIASES
MAILER-DAEMON:	postmaster
postmaster:	root

# General redirections for pseudo accounts
bin:		root
daemon:		root
named:		root
nobody:		root, n905i.1214@gmail.com
uucp:		root
www:		root, java@java.com
                     ALIASES
    }
    it 'remove target' do
      expect(
        aliases_parser.rm('n905i.1214@gmail.com', from: %w(www named))
      ).to eq expected
    end

    context 'when FROM=ALL' do
      let(:expected) { <<-ALIASES
MAILER-DAEMON:	postmaster
postmaster:	root

# General redirections for pseudo accounts
bin:		root
daemon:		root
named:		root
nobody:		root
uucp:		root
www:		root, java@java.com
                       ALIASES
      }

      it 'remove all target' do
        expect(
          aliases_parser.rm('n905i.1214@gmail.com', from: %w(ALL))
        ).to eq expected
      end
    end

    context 'when inputed unknown label' do
      it 'be exception' do
        expect {
          aliases_parser.rm('n905i.1214@gmail.com', from: %w(hoge))
        }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#list' do
    let(:expected) { 'named,nobody,www' }
    it 'return labels' do
      expect(
        aliases_parser.list('n905i.1214@gmail.com')
      ).to eq expected
    end
  end
end
