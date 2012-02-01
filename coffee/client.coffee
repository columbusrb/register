$ ->
  socket       = io.connect(window.location.hostname)
  source       = $("#entry-template").html()
  template     = Handlebars.compile(source)
  target       = $("tbody")

  prependEntry = (entry) ->
    presenter           = entry
    presenter.cssClass  = if entry.winner is true then "winner" else ""
    presenter.newToCrb  = if entry.new_to_crb is true then "Welcome" else ""
    presenter.newToRuby = if entry.new_to_ruby is true then "Welcome" else ""
    row = target.prepend(template(presenter)).children(":first").hide().fadeIn(1500)
    row.find('.gravatar img').mouseenter() if entry.winner

  clearWinner = ->
    $('.winner').removeClass("winner")
    $(".gravatar img").mouseleave()

  socket.on "updateProgressBar", (percentage) ->
    $('.progress .bar').css('width', "#{percentage}%")

  socket.on "newEntryPosted", (entry) ->
    prependEntry entry

  socket.on "hideWinner", (num) ->
    clearWinner()

  socket.on "showWinner", (num) ->
    rows   = $('tbody tr')
    winner = rows.eq(parseInt(num) - 1)
    middle = winner.offset().top - ($(window).height() / 2)
    clearWinner()
    $("html, body").animate {scrollTop: middle}, 500, ->
      winner.effect("pulsate", {times: 1}).addClass("winner").find(".gravatar img").mouseenter()

  socket.on "clearEntries", =>
    $('tbody tr').fadeOut 1000, -> $(this).remove()

  socket.on "updatedEntryCount", (count) ->
    $("#count").html count + " attendees"

  $("#admin-link").click ->
    $(this).hide()
    $("#admin-area").slideDown 'fast'
    $("#unlock-code").focus()

  $("#unlock-code").keyup (e) ->
    input = $(this)
    box   = $('#admin-area')
    if input.val().length is window.length
      $.post "/unlock", {code: input.val()}, (response) ->
        if response is true
          box.slideUp 'fast', ->
            input.val("").hide()
            $("#actions").show()
            box.slideDown 'fast'
        else
          box.slideUp 'fast'
          input.val ""

  $("#name, #email, #license").bind "keyup change", (e) ->
    $("#save").removeClass "disabled"
    $(this).removeClass "error"

  $("#save").click (e) ->
    e.preventDefault()
    nameInput          = $("input#name")
    emailInput         = $("input#email")
    twitterInput       = $("input#twitter")
    licenseSelect      = $("select#license")
    newToRubyCheckbox  = $("input#new_to_ruby")
    newToCrbCheckbox   = $("input#new_to_crb")
    submitButton       = $(this)
    fields             = [nameInput, emailInput, twitterInput, licenseSelect, newToRubyCheckbox, newToCrbCheckbox]
    submittable        = true
    data               = {}
    validate           = (input, failure) ->
      if input.val() isnt failure then storeValue(input) else disableInput(input)

    disableInput = (input) ->
      input.addClass "error"
      submitButton.addClass "disabled"
      submittable = false

    storeValue = (input) ->
      input.removeClass "error"
      value = if input.attr('type') is 'checkbox' then input.is(':checked') else input.val()
      data[input.attr("id")] = value

    $.each fields, (i, input) ->
      if input is nameInput or input is emailInput
        validate input, ""
      else if input is licenseSelect
        validate input, "Preferred License"
      else
        storeValue input

      # An unchecked checkbox will return false and kill the loop
      return true

    if submittable
      data.hash    = Crypto.MD5(emailInput.val())
      data.twitter = data.twitter.replace("@", "")
      socket.emit "submitEntry", data
      $("#new-entry-form").remove()
      $.each fields, (i, input) -> input.val ""

  $("#clear-winner").click (e) ->
    e.preventDefault()
    socket.emit "winnerCleared"

  $("#random-entry").click (e) ->
    e.preventDefault()
    rows   = $('tbody tr')
    row   = Math.ceil(Math.random() * rows.length)
    email = rows.eq(row - 1).find(".email").html()
    socket.emit "winnerChosen", {row: row, email: email}

  $(".gravatar img").live
    mouseenter: -> $(this).stop().animate {width: "64px", height: "64px"}, 500
    mouseleave: -> $(this).stop().animate {width: "24px", height: "24px"}, 500

  $("#save-entries").click (e) ->
    e.preventDefault()
    $("#admin-area").fadeOut 1000
    socket.emit "consumeEntries"

  $(window).keyup (e) ->
     $('#admin-area').slideUp 'fast' if e.keyCode is 27

  $.each window.entries, (i, entry) ->
    prependEntry entry

