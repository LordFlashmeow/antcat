# coding: UTF-8
class Bolton::Reference < ActiveRecord::Base
  include ReferenceComparable
  set_table_name :bolton_references

  belongs_to :reference
  has_many :matches, :class_name => 'Bolton::Match', :foreign_key => :bolton_reference_id
  has_many :references, :through => :matches

  before_validation :set_year

  searchable do
    text :original
    integer :id
  end

  def self.do_search options = {}
    query =
      select('DISTINCT bolton_references.*').
        joins('LEFT OUTER JOIN bolton_matches ON bolton_matches.bolton_reference_id = bolton_references.id').
        paginate(:page => options[:page])

    if options[:match_threshold].present?
      query = query.where 'similarity <= ?', options[:match_threshold]
    end

    if options[:q].present?
      solr_result_ids = search {
        keywords options[:q]
        order_by :id
        paginate :per_page => 5_000
      }.results.map &:id
      query = query.where('bolton_references.id' => solr_result_ids).paginate(:page => options[:page])
    end

    query
  end

  def to_s
    "#{authors} #{year}. #{title}."
  end

  # ReferenceComparable
  def author; authors.split(',').first; end
  def type; reference_type; end

  private
  def set_year
    self.year = ::Reference.get_year citation_year
  end

end
