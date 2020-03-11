def find_reference_by_keey keey
  parts = keey.split ','
  last_name = parts[0]
  year = parts[1]
  Reference.where("author_names_string_cache LIKE ?", "#{last_name}%").find_by(year: year.to_i)
end

Given("there is a reference") do
  create :article_reference
end

Given("there is an article reference") do
  create :article_reference
end

Given("there is a book reference") do
  create :book_reference
end

Given("there is an unknown reference") do
  create :unknown_reference
end

Given("this/these reference(s) exist(s)") do |table|
  table.hashes.each do |hash|
    citation = hash.delete('citation') || "Psyche 1:1"
    matches = citation.match /(\w+) (\d+):([\d\-]+)/
    journal = create :journal, name: matches[1]

    hash.merge!(journal: journal, series_volume_issue: matches[2], pagination: matches[3])

    if (author = hash.delete 'author')
      author_name = AuthorName.find_by(name: author) || create(:author_name, name: author)
      hash[:author_names] = [author_name]
    end

    create :article_reference, hash
  end
end

Given("the following entry nests it") do |table|
  data = table.hashes.first
  NestedReference.create!(
    title: data[:title],
    author_names: [create(:author_name, name: data[:author])],
    citation_year: data[:citation_year],
    pagination: data[:pagination],
    nesting_reference: Reference.last
  )
end

Given("a Hölldobler-Fisher reference exists with the title {string}") do |title|
  author_names = [
    AuthorName.find_by(name: "Hölldobler, B."),
    AuthorName.find_by(name: "Fisher, B.")
  ]
  create :unknown_reference, author_names: author_names, title: title
end

When('I fill in "reference_nesting_reference_id" with the ID for {string}') do |title|
  reference = Reference.find_by(title: title)
  step %(I fill in "reference_nesting_reference_id" with "#{reference.id}")
end

Then("I should see a PDF link") do
  find "a", text: "PDF", match: :first
end

When("I fill in {string} with a URL to a document that exists") do |field_name|
  stub_request :any, "google.com/foo"
  step %(I fill in "#{field_name}" with "google\.com/foo")
end

Given("the default reference is {string}") do |keey|
  reference = find_reference_by_keey keey
  DefaultReference.stub(:get).and_return reference
end

Then("nesting_reference_id should contain a valid reference id") do
  id = find("#reference_nesting_reference_id").value
  expect(Reference.exists?(id)).to be true
end

Given("there is a reference referenced in a history item") do
  reference = create :article_reference
  create :taxon_history_item, taxt: "{ref #{reference.id}}"
end

Then("the {string} tab should be selected") do |tab_name|
  tab_name = 'Unknown' if tab_name == 'Other'
  find("#tabs-#{tab_name.downcase}.is-active")
end
