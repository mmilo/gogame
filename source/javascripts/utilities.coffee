window.getParameterByName = (name) ->
  name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]")
  regex = new RegExp("[\\?&]" + name + "=([^&#]*)")
  results = regex.exec(location.search)
  if results?
    decodeURIComponent(results[1].replace(/\+/g, " "))
  else
    null

window.secondsToTime = (milliseconds) ->
  secs = milliseconds / 1000

  days =  Math.floor(secs / (60 * 60 * 24))


  divisor_for_hours = secs % (60 * 60 * 24)
  hours = Math.floor(divisor_for_hours / (60 * 60))

  divisor_for_minutes = secs % (60 * 60)
  minutes = Math.floor(divisor_for_minutes / 60)

  divisor_for_seconds = divisor_for_minutes % 60
  seconds = Math.ceil(divisor_for_seconds)

  if days
    "#{days}d #{hours}h #{minutes}m #{seconds}s"
  else if hours
    "#{hours}h #{minutes}m #{seconds}s"
  else if minutes
    "#{minutes}m #{seconds}s"
  else if seconds
    "#{seconds}s"
