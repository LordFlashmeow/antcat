require 'spec_helper'

describe Bolton::GenusCatalog do
  before do
    @genus_catalog = Bolton::GenusCatalog.new
  end

  describe 'importing files' do
    it "should call #import_html with the contents of each one" do
      File.should_receive(:read).with('first_filename').and_return('first contents')
      File.should_receive(:read).with('second_filename').and_return('second contents')
      @genus_catalog.should_receive(:import_html).with('first contents')
      @genus_catalog.should_receive(:import_html).with('second contents')
      @genus_catalog.import_files ['first_filename', 'second_filename']
    end
  end

  describe 'importing html' do
    it "should call the parser and save the result" do
      Bolton::GenusCatalogParser.should_receive(:parse).with('foo').and_return :genus => {:name => 'bar'}
      Genus.should_receive(:create!).with :name => 'bar'
      @genus_catalog.import_html '<html><p>foo</p></html>'
    end
    it "should call the parser and not save the result if it wasn't a genus" do
      Bolton::GenusCatalogParser.should_receive(:parse).with('foo').and_return nil
      Genus.should_not_receive :create!
      @genus_catalog.import_html '<html><p>foo</p></html>'
    end
  end

#  describe 'parsing the genus header' do
#    before do
#      @genus_contents = %q{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
#style='color:red'>brevicornis</span></i></b><i style='mso-bidi-font-style:normal'>.
#Acanthognathus brevicornis</i> Smith, M.R. 1944c: 151 (w.q.) PANAMA. See also:
#Brown &amp; Kempf, 1969: 94; Bolton, 2000: 16.</p>
#      }
#    end
#    it "should recognize a valid, extant genus heading" do
#      @genus_catalog.import_html make_contents %Q{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
#style='color:red'>ACANTHOGNATHUS</span></i></b> (Neotropical)</p>
#      #{@genus_contents}
#      }
#      Genus.count.should == 1
#      Genus.first.name.should == 'Acanthognathus brevicornis'
#    end
#  end

#  describe 'parsing a genus line' do
#    before do
#      @genus_contents = %q{
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
#style='color:red'>ACANTHOGNATHUS</span></i></b> (Neotropical)</p>
#      }
#    end
#    it "should recognize a valid, extant genus line" do
#      @genus_catalog.import_html make_contents %Q{
#      #{@genus_contents}
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
#style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
#style='color:red'>brevicornis</span></i></b><i style='mso-bidi-font-style:normal'>.
#Acanthognathus brevicornis</i> Smith, M.R. 1944c: 151 (w.q.) PANAMA. See also:
#Brown &amp; Kempf, 1969: 94; Bolton, 2000: 16.</p>
#      }
#      Genus.count.should == 1
#      Genus.first.name.should == 'Acanthognathus brevicornis'
#    end
#  end

#  def make_contents content
#    %Q{
#<html> <head> <title>CATALOGUE OF SPECIES-GROUP TAXA</title> </head>
#<body>
#<div class=Section1>
#<p class=MsoNormal align=center style='margin-left:.5in;text-align:center;
#text-indent:-.5in'><b style='mso-bidi-font-weight:normal'>CATALOGUE OF
#SPECIES-GROUP TAXA<o:p></o:p></b></p>
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
##{content}
#<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
#</div> </body> </html>
#    }
#  end
  #  it "should handle the first entries" do
  #    contents = <<-CONTENTS
  #      <html 
  #        <head>
  #        </head>
  #        <body lang=EN-US style='tab-interval:.5in'>
  #          <div class=Section1>
  #            <p class=MsoNormal align=center style='margin-left:.5in;text-align:center;
  #            text-indent:-.5in'><b style='mso-bidi-font-weight:normal'>CATALOGUE OF
  #              GENUS-GROUP TAXA<o:p></o:p></b></p>
  #            <p class=MsoNormal style='text-align:justify'><o:p>&nbsp;</o:p></p>
  #            <p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>

  #            <p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
  #            style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
  #            style='color:red'>AMBLYOPONE</span></i></b> [Amblyoponinae]</p>

  #            <p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><i
  #            style='mso-bidi-font-style:normal'>Amblyopone</i> Erichson, 1842: 260.
  #            Type-species: <i style='mso-bidi-font-style:normal'>Amblyopone australis</i>,
  #            by monotypy. </p>

  #            <p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><i
  #            style='mso-bidi-font-style:normal'>Amblyopone</i> senior synonym of <i
  #            style='mso-bidi-font-style:normal'>Stigmatomma</i>: Emery &amp; Forel, 1879:
  #            455; Mayr, 1887: 546.</p>

  #            <p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
  #          </div>
  #        </body>
  #      </html>
  #    CONTENTS

  #    File.should_receive(:read).with('subfamily_genus.html').and_return(contents)
  #    Bolton::Importer.new.get_subfamilies('subfamily_genus.html').should == [{:genus => 'Amblyopone'}]
  #  end
  #end

  #def make_contents content
  #  "<html>
  #      <body>
  #    <p class=MsoNormal align=center style='margin-left:.5in;text-align:center;
  #    text-indent:-.5in'><b style='mso-bidi-font-weight:normal'>CATALOGUE OF
  #      GENUS-GROUP TAXA<o:p></o:p></b></p>

  #    <p class=MsoNormal style='text-align:justify'><o:p>&nbsp;</o:p></p>

  #    <p class=MsoNormal style='text-align:justify'><o:p>&nbsp;</o:p></p>

  #    #{content}
  #      </body>
  #    </html>
  #  "
  #end
end
