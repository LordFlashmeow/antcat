

$ ->
  $.ajax '/tooltips/enabled_selectors', success: (data) -> # TODO improve this
    tooltipsToInsert = data
    (new AntCat.SelectorTooltips).createTooltips tooltipsToInsert
    (new AntCat.Tooltipify).tooltipifyAll()


$ ->
  $.ajax '/tooltips/render_missing_tooltips', success: (data) ->

    # TODO: make it so that if you cick an "edit" icon, if there's already a live tooltip, edit that one instead.

    # TODO: Some way to organize this on a per-screen basis. selectors will be unique on a per screen basis,
    #       but are unlikely to be universal.
    #       have it pass an argument
    # TODO: A button to toggle this feature once or to toggle on/off
    # TEST: Click on (I), create a tooltip, save it, end up on origin page with new tooltip visible
    # Test, go to tooltip creation directly, create a tooltip, save it, remain on tooltip page.

    # TODO: Have this generate the tooltip after you click on it.
    selector_generator = new CssSelectorGenerator

    if data.show_missing_tooltips == true
      $('label, button, .ui-button').not('.display_button').each (index, element) =>
        $(element).after("""\
          <a class = "create_tooltip" > \
          <img class="help_icon tooltip " \
           title="Create tooltip" src="/assets/create_tip.png" alt="Help" /></a>\
           """)
        $(element).next().click  ->
          selector = encodeURIComponent(selector_generator.getSelector(element));
          $(this).attr('href',"/tooltips/new/?selector=" +
              selector +
              "&referral=" +
              encodeURIComponent(window.location.href))


  #
#    $('.create_tooltip').on 'click', ->
#      selector_generator = new CssSelectorGenerator
#      selector = encodeURIComponent(selector_generator.getSelector($(this).parent()));
#      parent = $(this).parent()
#      selector2 = selector_generator.getSelector(parent)
#      alert("foo" + selector2)



  # Added to the global window object to make it callable from anywhere.
  window.testTooltipSelector = (new AntCat.TestTooltipSelector).testTooltipSelector

class AntCat.SelectorTooltips
  SELECTOR_TOOLTIP_CLASS = 'selector-tooltip'
  SELECTOR_TEST_TOOLTIP_CLASS = 'selector-test-tooltip'

  # Accepts an array of arrays in this format: [['jquery_selector', 'tooltip_text', 'id']]
  createTooltips: (tooltips) ->
    for tooltip in tooltips
      selector = tooltip[0]
      title = tooltip[1]
      id = tooltip[2]
      @createTooltip selector, title, id

  createTooltip: (selector, title, id, test_tooltip = false) =>
    disable_edit_link = false # TODO add this, currently it's not possible to disable

    iconElement = $(@_createIcon title, id)
    iconElement.addClass(SELECTOR_TEST_TOOLTIP_CLASS) if test_tooltip

    iconElement.insertAfter $(selector)

  removeAllSelectorTestTooltips: -> $(".#{SELECTOR_TEST_TOOLTIP_CLASS}").remove()

  _createIcon: (title, id) => # TODO move the link from this function
    """<a class="#{SELECTOR_TOOLTIP_CLASS}" href="/tooltips/#{id}">\
       <img class="help_icon tooltip #{SELECTOR_TOOLTIP_CLASS}" \
       title="#{title}" src="/assets/help.png" alt="Help" /></a>"""

class AntCat.Tooltipify
  # Wrapper function that formats the tooltips.
  #
  # `$('.tooltip').tooltip()` is built-into jQuery UI; it takes a selector
  # (class="tooltip" by convention), and "tooltipifies" all elements matching that selector;
  # whatever is in the `title` attribute on those elements is used as the tooltip text.
  tooltipifyAll: ->
    $('.tooltip').tooltip
      show: false # show immediately
      content: -> $(this).prop('title') # Without this, HTML is displayed as text.
      position:
        my: "left top"
        at: "right bottom"
      close: (event, ui) -> # Keep open if the tooltip is hovered.
        startHoverHandler = -> $(this).stop(true)
        stopHoverHandler = -> $(this).remove()
        ui.tooltip.hover startHoverHandler, stopHoverHandler

# For letting editors test selectors; works in all views where tooltips are enabled.
# It is only possible to test one selector at the time -- all other test tooltips
# are removed before inserting the new one.
#
# To test a selector, paste this snippet into your browser's JavaScript console:
#   testTooltipSelector('label[for="reference_title"]');
# A second and third arguments are optional (for the tooltip text and id):
#   testTooltipSelector('label[for="reference_title"]', "Wololoo", "9999");
#
# This method is exposed on the global window object in jQuery's .ready function.
class AntCat.TestTooltipSelector
  testTooltipSelector: (selector, title = 'test', id = '99999') ->
    engine = new AntCat.SelectorTooltips
    engine.removeAllSelectorTestTooltips()
    test_tooltip = true
    engine.createTooltip selector, title, id, test_tooltip
    (new AntCat.Tooltipify).tooltipifyAll()