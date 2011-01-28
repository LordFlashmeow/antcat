require 'spec_helper'

describe Bolton::SpeciesCatalog do
  before do
    @species_catalog = Bolton::SpeciesCatalog.new
  end

  it "importing a file should call #import_html" do
    File.should_receive(:read).with('filename').and_return('contents')
    @species_catalog.should_receive(:import_html).with('contents')
    @species_catalog.import_files ['filename']
    Species.all.should be_empty
  end

  describe 'parsing the file as a whole' do
    it 'should complain bitterly if file is obviously not a species catalog' do
     contents = %{<html><body> <p>Foo</p> </body></html>}
     Progress.should_receive(:error).with("Foo\n")
     @species_catalog.import_html contents
    end

    it "should parse a header + see-under + genus-section without complaint" do
      contents = make_contents %{
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><i
style='mso-bidi-font-style:normal'>ACANTHOLEPIS</i>: see under <b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'>LEPISIOTA</i></b>.</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>ACANTHOMYRMEX</span></i></b> (Oriental, Indo-Australian)</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>basispinosus</span></i></b><i style='mso-bidi-font-style:
normal'>. Acanthomyrmex basispinosus</i> Moffett, 1986c: 67, figs. 8A, 9-14
(s.w.) INDONESIA (Sulawesi).</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>ANONYCHOMYRMA</span></i></b> (Indo-Australian, Australia)</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>anguliceps</span></i></b><i style='mso-bidi-font-style:normal'>.
Iridomyrmex anguliceps</i> Forel, 1901b: 18 (q.m.) NEW GUINEA (Bismarck
Archipelago). Combination in <i style='mso-bidi-font-style:normal'>Anonychomyrma</i>:
Shattuck, 1992a: 13.</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>angusta</span></i></b><i style='mso-bidi-font-style:normal'>.
Iridomyrmex angustus</i> Stitz, 1911a: 369, fig. 15 (w.) NEW GUINEA.
Combination in <i style='mso-bidi-font-style:normal'>Anonychomyrma</i>:
Shattuck, 1992a: 13.</p>
      }

      Progress.should_not_receive(:error)
      @species_catalog.import_html contents
    end

    it "should recover from one species it can't parse and continue with the rest" do
      contents = make_contents %{
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>ANONYCHOMYRMA</span></i></b> (Indo-Australian, Australia)</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>anguliceps</span></i></b><i style='mso-bidi-font-style:normal'>.
Iridomyrmex anguliceps</i> Forel, 1901b: 18 (q.m.) NEW GUINEA (Bismarck
Archipelago). Combination in <i style='mso-bidi-font-style:normal'>Anonychomyrma</i>:
Shattuck, 1992a: 13.</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><span>foo</span></p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>angusta</span></i></b><i style='mso-bidi-font-style:normal'>.
Iridomyrmex angustus</i> Stitz, 1911a: 369, fig. 15 (w.) NEW GUINEA.
Combination in <i style='mso-bidi-font-style:normal'>Anonychomyrma</i>:
Shattuck, 1992a: 13.</p>
      }

      Progress.should_receive(:error).once
      @species_catalog.import_html contents
    end

    it "should skip by subspecies and notes" do
      contents = make_contents %{
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>ANONYCHOMYRMA</span></i></b> (Indo-Australian, Australia)</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>anguliceps</span></i></b><i style='mso-bidi-font-style:normal'>.
Iridomyrmex anguliceps</i> Forel, 1901b: 18 (q.m.) NEW GUINEA (Bismarck
Archipelago). Combination in <i style='mso-bidi-font-style:normal'>Anonychomyrma</i>:
Shattuck, 1992a: 13.</p>

<p>#<b><i><span style="color:blue">ajax</span></i></b><i>. Atta (Acromyrmex) emilii</i> var. <i>ajax</i> Forel, 1909b: 58 (w.) "GUINEA" (in error; in text Forel states "probablement du Brésil"). Currently subspecies of <i>hystrix</i>: Santschi, 1925a: 358.</p>

<p><span style="color:black">[Note. All <i>Colobostruma</i> taxa with combination in <i>Epopostruma</i>, <i>sensu</i> Baroni Urbani &amp; De Andrade, 2007: 97-98.]</span></p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>angusta</span></i></b><i style='mso-bidi-font-style:normal'>.
Iridomyrmex angustus</i> Stitz, 1911a: 369, fig. 15 (w.) NEW GUINEA.
Combination in <i style='mso-bidi-font-style:normal'>Anonychomyrma</i>:
Shattuck, 1992a: 13.</p>
      }

      Progress.should_not_receive :error
      @species_catalog.import_html contents
    end
  end

  describe "parsing a note" do
    it "should work" do
      @species_catalog.parse(%{<span style="color:black">[Note. All <i>Colobostruma</i> taxa with combination in <i>Epopostruma</i>, <i>sensu</i> Baroni Urbani &amp; De Andrade, 2007: 97-98.]</span>}).should == {:type => :note}
    end
  end

  def make_contents content
    %{
<html> <head> <title>CATALOGUE OF SPECIES-GROUP TAXA</title> </head>
<body>
<div class=Section1>
<p class=MsoNormal align=center style='margin-left:.5in;text-align:center;
text-indent:-.5in'><b style='mso-bidi-font-weight:normal'>CATALOGUE OF
SPECIES-GROUP TAXA<o:p></o:p></b></p>
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>
      #{content}
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>
</div> </body> </html>
    }
  end
end
