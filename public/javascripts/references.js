$(function() {
  //$.fn.ajaxSubmit.debug = true
  setupSearch();
  if (loggedIn) {
    setupAddReferenceLink();
    setupDisplays();
    setupEdits();
  }
  //if (!usingCucumber) {
    //addReference();
  //}
})

function setupSearch() {
  setupSearchAutocomplete();
  $("#start_year").keyup(function(event) {
    if (event.which != 9)
      $("#end_year").val($(this).val());
  });
}

/////////////////////////////////////////////////////////////////////////

function setupAddReferenceLink() {
  showAddReferenceLink();
  $('.add_reference_link').click(addReference);
}

function showAddReferenceLink() {
  if ($('.reference').size() == 0)
    $('.add_reference_link').show();
  else
    hideAddReferenceLink();
}

function hideAddReferenceLink() {
  $('.add_reference_link').hide();
}

/////////////////////////////////////////////////////////////////////////

function setupDisplays() {
  $('.source_link').live('click', viewSource);
  $('.reference_display').live('click', editReference);
  $('.reference_display').addClass('editable');

  setupIcons();
}

function setupIcons() {
  if (!usingCucumber)
    $('.icon').hide();
  else
    $('.icon').show();

  $('.reference').live('mouseenter',
    function() {
      if (!isEditing())
        $('.icon', $(this)).show();
    }).live('mouseleave',
    function() {
      $('.icon').hide();
    });

  $('.icon img').live('mouseenter',
    function() {
      this.src = this.src.replace('off', 'on');
    }).live('mouseleave',
    function() {
      this.src = this.src.replace('on', 'off');
    });

  $('.icon.edit').live('click', editReference);
  $('.icon.add').live('click', insertReference);
  $('.icon.copy').live('click', copyReference);
  $('.icon.delete').live('click', deleteReference);
}

function setupEdits() {
  $('.reference_edit').hide();
  $('.reference_edit .cancel').live('click', cancelReferenceEdit);
  $('.reference_edit .delete').live('click', deleteReference);
}

///////////////////////////////////////////////////////////////////////////////////

function viewSource() {
  window.location = this.href;
  return false;
}

function editReference() {
  if (isEditing())
    return false;

  $reference = $(this).closest('.reference');
  saveReference($reference);
  showReferenceEdit($reference, {showDeleteButton: true});
  return false;
}

function deleteReference() {
  $reference = $(this).closest('.reference');
  $reference.addClass('about_to_be_deleted');
  if (confirm('Do you want to delete this reference?')) {
    $.post($reference.find('form').attr('action'), {'_method': 'delete'})
    $reference.closest('tr').remove();
  } else
    $reference.removeClass('about_to_be_deleted');

  showAddReferenceLink();
  return false;
}

function addReference() {
  addOrInsertReferenceEdit(null);
  return false;
}

function insertReference() {
  addOrInsertReferenceEdit($(this).closest('.reference'));
  return false
}

function copyReference() {
  $rowToCopyFrom = $(this).closest('tr.reference_row');
  $newRow = $rowToCopyFrom.clone(true);
  $rowToCopyFrom.after($newRow);
  $newReference = $('.reference', $newRow);
  $newReference.attr("id", "reference_");
  $('form', $newReference).attr("action", "/references");
  $('[name=_method]', $newReference).attr("value", "post");
  showReferenceEdit($newReference);
  return false;
}

function addOrInsertReferenceEdit($reference) {
  $referenceTemplateRow = $('.reference_template_row');
  $newReferenceRow = $referenceTemplateRow.clone(true);
  $newReferenceRow.removeClass('reference_template_row').addClass('reference_row');
  $('.reference_template', $newReferenceRow).removeClass('reference_template').addClass('reference');

  if ($reference == null)
    $('.references').prepend($newReferenceRow);
  else
    $reference.closest('tr').after($newReferenceRow);

  $newReference = $('.reference', $newReferenceRow);
  showReferenceEdit($newReference);
}

///////////////////////////////////////////////////////////////////////////////////

function saveReference($reference) {
  $('#saved_reference').remove()
  $reference.clone(true)
    .attr('id', 'saved_reference')
    .appendTo('body')
    .hide()
}

function restoreReference($reference) {
  var id = $reference.attr('id');
  $reference.replaceWith($('#saved_reference'))
  $('#saved_reference').attr('id', id).show()
}

function showReferenceEdit($reference, options) {
  if (!options)
    options = {}


  hideAddReferenceLink();
  $('.reference_display', $reference).hide();
  $('.icon').hide();

  var $edit = $('.reference_edit', $reference);
  $('form', $edit).ajaxForm({beforeSerialize: beforeSerialize, beforeSubmit: setupSubmit, success: updateReference, dataType: 'json'});
  setTabs($reference);
  $edit.show();

  $('#reference_authors_string', $edit).focus();

  if (!options.showDeleteButton)
    $('.delete', $edit).hide();

  setupAuthorAutocomplete($reference);
  setupJournalAutocomplete($reference);
  setupPublisherAutocomplete($reference);
}

function setTabs($reference) {
  var id = $reference.attr('id');
  var selected_tab = $('.selected_tab', $reference).val();

  $('.tabs .article-tab', $reference).attr('href', '#reference_article' + id);
  $('.tabs .article-tab-section', $reference).attr('id', 'reference_article' + id);

  $('.tabs .book-tab', $reference).attr('href', '#reference_book' + id);
  $('.tabs .book-tab-section', $reference).attr('id', 'reference_book' + id);

  $('.tabs .other-tab', $reference).attr('href', '#reference_other' + id);
  $('.tabs .other-tab-section', $reference).attr('id', 'reference_other' + id);

  $('.tabs', $reference).tabs({selected: selected_tab});
}

function beforeSerialize($form, options) {
  var selectedTab = $.trim($('.ui-tabs-selected', $form).text())
  $('#selected_tab', $form).val(selectedTab)
  return true
}

function setupSubmit(formData, $form, options) {
  var $spinnerElement = $('button', $form).parent();
  $spinnerElement.spinner({position: 'left', img: '/stylesheets/ext/jquery-ui/images/ui-anim_basic_16x16.gif'});
  $('input', $spinnerElement).attr('disabled', 'disabled');
  $('button', $spinnerElement).attr('disabled', 'disabled');
  return true;
}

function updateReference(data, statusText, xhr, $form) {
  var $reference = $('#reference_' + (data.isNew ? '' : data.id));

  var $edit = $('.reference_edit', $reference);

  var $spinnerElement = $('button', $edit).parent();
  $('input', $spinnerElement).attr('disabled', '');
  $('button', $spinnerElement).attr('disabled', '');
  $spinnerElement.spinner('remove');

  $reference.parent().html(data.content);

  if (!data.success) {
    $reference = $('#reference_' + (data.isNew ? '' : data.id));
    showReferenceEdit($reference);
    return;
  }

  $reference = $('#reference_' + data.id);
  $('.reference_edit', $reference).hide();

  var $display = $('.reference_display', $reference);
  $display.show();
  $display.addClass('editable');
  $display.effect("highlight", {}, 3000);

  showAddReferenceLink();
}

function cancelReferenceEdit() {
  $reference = $(this).closest('.reference');
  if ($reference.attr('id') == 'reference_')
    $reference.closest('tr').remove();
  else {
    restoreReference($reference);
    $('.reference_display', $reference).show();
    $('.reference_edit', $reference).hide();
  }

  showAddReferenceLink();

  return false;
}

////////////////////////////////////////////////////////////////////////////////

function isEditing() {
  return $('.reference_edit').is(':visible');
}

