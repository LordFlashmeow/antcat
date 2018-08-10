$ ->
  TAXON_SELECT_SELECTOR = 'select[data-taxon-select]'
  $(TAXON_SELECT_SELECTOR).each -> $(this).taxonSelectify()

$.fn.taxonSelectify = ->
  selectElement = this
  return if $(selectElement).data('select2')

  $(selectElement).select2
    theme: 'bootstrap'
    templateResult: (item) ->
      return if item.loading
      "<small>##{item.id}</small> #{item.name_with_fossil} <small>#{item.author_citation}</small>"
    templateSelection: (item) ->
      return '(none)' unless item.id
      nameWithFossil = $(selectElement).data 'name-with-fossil'
      authorCitation = $(selectElement).data 'author-citation'
      "<small>##{item.id}</small> #{item.name_with_fossil || nameWithFossil} <small>#{item.author_citation || authorCitation}</small>"
    escapeMarkup: (m) -> m
    minimumInputLength: 1
    placeholder: '???'
    allowClear: true
    ajax:
      url: '/catalog/autocomplete'
      dataType: 'json'
      data: (params) -> { qq: params.term, rank: $(selectElement).data('rank') }
      processResults: (data) -> { results: data }
