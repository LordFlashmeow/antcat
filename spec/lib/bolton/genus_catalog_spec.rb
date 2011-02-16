require 'spec_helper'

describe Bolton::GenusCatalog do
  before do
    @genus_catalog = Bolton::GenusCatalog.new
  end

  describe "importing files" do
    it "should process them in alphabetical order (not counting extension), so the three Camponotus files get processed in the right order" do
      File.should_receive(:read).with('NGC-GEN.A-L.htm').ordered.and_return ''
      File.should_receive(:read).with('NGC-GEN.M-Z.htm').ordered.and_return ''
      @genus_catalog.import_files ['NGC-GEN.A-L.htm', 'NGC-GEN.M-Z.htm']
    end
  end

  describe 'importing html' do
    
    describe "processing a representative sample and making sure they're saved correctly" do
      it 'should work' do
        @genus_catalog.import_html make_content %{
<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>ACROMYRMEX</span></i></b> [Myrmicinae: Attini]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><o:p>&nbsp;</o:p></p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>#<b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:blue'>ALAOPONE</span></i></b> [subgenus of <i style='mso-bidi-font-style:
normal'>Dorylus</i>]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>*<b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:green'>ATTAICHNUS</span></i></b> [Myrmicinae: Attini]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><i
style='mso-bidi-font-style:normal'>Acamatus</i> Emery, 1894c: 181 [as subgenus
of <i style='mso-bidi-font-style:normal'>Eciton</i>]. Type-species: <i
style='mso-bidi-font-style:normal'>Eciton (Acamatus) schmitti</i> (junior
synonym of <i style='mso-bidi-font-style:normal'>Labidus nigrescens</i>), by
subsequent designation of Ashmead, 1906: 24; Wheeler, W.M. 1911f: 157. [Junior
homonym of <i style='mso-bidi-font-style:normal'>Acamatus </i>Schoenherr, 1833:
20 (Coleoptera).] </p>

<p class=MsoNormal><i style='mso-bidi-font-style:normal'><span
style='color:black'>ACALAMA</span></i> [junior synonym of <i style='mso-bidi-font-style:
normal'>Gauromyrmex</i>]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>#<b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:blue'>ACANTHOMYOPS</span></i></b> [subgenus of <i
style='mso-bidi-font-style:normal'>Lasius</i>]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><i
style='mso-bidi-font-style:normal'>ACAMATUS</i> [junior homonym, see <i
style='mso-bidi-font-style:normal'>Neivamyrmex</i>]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'><i
style='mso-bidi-font-style:normal'><span style='color:purple'>ANCYLOGNATHUS</span></i>
[<i style='mso-bidi-font-style:normal'>Nomen nudum</i>]</p>

<p class=MsoNormal style='margin-left:.5in;text-align:justify;text-indent:-.5in'>*<b
style='mso-bidi-font-weight:normal'><i style='mso-bidi-font-style:normal'><span
style='color:red'>PROTAZTECA</span></i></b> [<i style='mso-bidi-font-style:
normal'>incertae sedis</i> in Dolichoderinae]</p>
        }

        Genus.count.should == 8

        acromyrmex = Genus.find_by_name 'Acromyrmex'
        acromyrmex.should_not be_fossil
        acromyrmex.subfamily.name.should == 'Myrmicinae'
        acromyrmex.tribe.name.should == 'Attini'
        acromyrmex.should_not be_invalid
        acromyrmex.taxonomic_history.should == %{<p class="MsoNormal" style="margin-left:.5in;text-align:justify;text-indent:-.5in"><b style="mso-bidi-font-weight:normal"><i style="mso-bidi-font-style:normal"><span style="color:red">ACROMYRMEX</span></i></b> [Myrmicinae: Attini]</p>}

        attaichnus = Genus.find_by_name 'Attaichnus'
        attaichnus.should be_fossil
        attaichnus.should be_unidentifiable

        acalama = Genus.find_by_name 'Acalama'
        acalama.should_not be_fossil
        acalama.should be_synonym
        acalama.should be_invalid
        acalama.synonym_of.name.should == 'Gauromyrmex'

        ancylognathus = Genus.find_by_name 'Ancylognathus'
        ancylognathus.should_not be_available
        
        protazteca = Genus.find_by_name 'Protazteca'
        protazteca.tribe.name.should == 'incertae_sedis'
        protazteca.subfamily.name.should == 'Dolichoderinae'

        acamatus = Genus.find_by_name 'Acamatus'
        acamatus.should be_homonym
        acamatus.should be_invalid
        acamatus.homonym_of.name.should == 'Neivamyrmex'

      end
    end

    def make_content content
      %{<html> <head> <title>CATALOGUE OF GENUS-GROUP TAXA</title> </head>
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

end
