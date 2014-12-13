# Game logic for the board game Go
class Go.Game extends Backbone.Model
  constructor: (options) ->
    @size = options.size
    @clickSound = new Audio("/sounds/click.wav")
    @resetBoard()

    @firebase = new Firebase("https://intense-fire-8240.firebaseio.com/games/#{options.game_id}")

    @firebase.child('players').on 'value', (snapshot) =>
      @players = snapshot.val() || {}
      if @players[Go.BLACK]? and @players[Go.WHITE]?
        @firebase.setPriority(Go.STATUS.FULL)
      else if @players[Go.BLACK]? or @players[Go.WHITE]?
        @firebase.setPriority(Go.STATUS.WAITING)

    @firebase.child('moves').on 'value', (snapshot) =>
      moves = snapshot.val() || {}
      try
        if @accepted_moves.length > _.keys(moves).length
          throw("Firebase rejected a move - rollback")

        # Play / replay moves
        _.each moves, (move, key, moves) =>
          # Skip moves that have already been played
          if @movesAreEqual(@accepted_moves[move.index], move)
            # Don't need to replay existing moves
            console.log("Not replaying move ##{move.index}, (#{if move.pass then 'pass' else "#{move.x}, #{move.y}"})")
          else if @accepted_moves[move.index]?
            throw("Conflict in moves - Start over")
          else
            # Replay the new move
            @play(move, replaying: true)
          # Take the played_at value generated by the server
          @accepted_moves[move.index].played_at = move.played_at
       
      catch error
        console.log "ERROR: #{error}"
        # Start fresh and replay all the moves
        @resetBoard()
        _.each moves, (move, key, moves) => @play(move, replaying: true)

      offsetRef = new Firebase("https://intense-fire-8240.firebaseIO-demo.com/.info/serverTimeOffset")
      offsetRef.on "value", (snap) => @serverTimeOffset = snap.val()

      @trigger('ready')

  resetBoard: =>
    @game_is_over = false
    @in_atari = false
    @attempted_suicide = false
    @accepted_moves = []
    @prisoners = {}
    @prisoners[Go.BLACK] = @prisoners[Go.WHITE] = 0
    @board = @create_board()
    @trigger('board_state_changed')

  join: (userId, color) =>
    if !@players[color]?
      @firebase.child('players').child(color).set(userId)
      return true
    else
      # No available place
      return false

  # Returns a size x size matrix with all entries initialized to Go.EMPTY
  create_board: =>
    m = []
    i = 0
    while i < @size
      m[i] = []
      j = 0
      while j < @size
        m[i][j] = Go.EMPTY
        j++
      i++
    m

  current_color: ->
    if @move_number() % 2 is 0
      Go.BLACK
    else
      Go.WHITE

  move_number: ->
    # The number of keys is automatically the greatest key + 1
    @accepted_moves.length

  lastMove: ->
    _.last(@accepted_moves)

  lastStone: ->
    move = _.last(_.where(@accepted_moves, { pass: false }))
    if move
      { x: move.x, y: move.y }
    else
      {}

  showPlayerPassed: (color) ->
    return false unless @lastMove()?.pass

    if @current_color() is color
      # Only show pass for the current player if the move befor
      # was also a pass. (ie. Don't show "passed" while still playing)
      return @accepted_moves[@accepted_moves.length - 2]?.pass
    else
      true

  # Called when the game ends (both players passed)
  end_game: ->
    @game_is_over = true
    console.log "GAME OVER"
    @firebase.setPriority(Go.STATUS.ENDED)
    return

  play: (move, options={}) =>
    if move.pass
      console.log "Attempting to #{if options.replaying then 'Re-' else ''}Play PASS"
    else
      console.log "Attempting to #{if options.replaying then 'Re-' else ''}Play move at " + move.x + ", " + move.y

    # Only permit each player to take their own turn
    if !options.replaying
      if @players[@current_color()] isnt Go.current_user.uid
        console.warn "Ignoring move played out of turn."
        return false
      if @game_is_over
        console.warn "Ignoring move - the game is over"
        return false

    if move.pass
      @end_game() if @accepted_moves[@move_number()-1]?.pass
      @accept_move(move, options.replaying)
      return true
    else if move.x? and move.y?
      i = move.x
      j = move.y
    else
      throw 'Invalid move attempted'

    @attempted_suicide = @in_atari = false
    return false unless @board[i][j] is Go.EMPTY
    color = @board[i][j] = @current_color()
    captured = []
    neighbors = @get_adjacent_intersections(i, j)
    atari = false
    _.each neighbors, (n) =>
      state = @board[n[0]][n[1]]
      if state isnt Go.EMPTY and state isnt color
        group = @get_group(n[0], n[1])
        console.log group
        if group["liberties"] is 0
          captured.push group
        else atari = true  if group["liberties"] is 1
      return

    # detect suicide
    if _.isEmpty(captured) and @get_group(i, j)["liberties"] is 0
      @board[i][j] = Go.EMPTY
      @attempted_suicide = true
      return false
    _.each captured, (group) =>
      _.each group["stones"], (stone) =>
        @prisoners[@board[stone[0]][stone[1]]] += 1
        @board[stone[0]][stone[1]] = Go.EMPTY
        return

      return

    @in_atari = true  if atari

    # Store the move unless we're replaying
    @accept_move(move, options.replaying)
    true

  accept_move: (move, replaying=false) ->
    # Set and normalise attributes
    if move.pass is true
      move.x = move.y = null
    else
      move.pass = false
    move = { x: move.x, y: move.y, pass: move.pass, index: @move_number(), played_at: move.played_at }
    # Register that it's been played at that index in the @accepted_moves
    @accepted_moves[move.index] = move
    # Store it in Firebase
    unless replaying
      move.played_at = Firebase.ServerValue.TIMESTAMP
      @firebase.child("moves/move-#{move.index}").setWithPriority(move, move.index)
    if move.pass
      # TODO: Play pass sound
    else
      @clickSound.play()
    # Trigger event for views

    @trigger('board_state_changed')

  playerTimes: ->
    moves = _.clone(@accepted_moves)
    split_times = {}
    split_times[Go.BLACK] = _.reduce(moves, (memo, move) ->
      duration = if move.index > 0 then move.played_at - moves[move.index-1].played_at else 0
      memo + (if move.index % 2 is 0 then duration else 0)
    , 0)
    split_times[Go.WHITE] = _.reduce(moves, (memo, move) ->
      duration = if move.index > 0 then move.played_at - moves[move.index-1].played_at else 0
      memo + if move.index % 2 is 1 then duration else 0
    , 0)

    if !@game_is_over and (lastMove = _.last(moves))?
      split_times[@current_color()] += (@serverTime() - lastMove.played_at)

    split_times

  # Sanitize a move for storage and strip extra attributes for isObject comparisons
  movesAreEqual: (move_a, move_b) ->
    return false if !move_a or !move_b
    return false unless move_a.index is move_b.index
    return true if move_a.pass and move_b.pass
    return true if move_a.x is move_b.x and move_a.y is move_b.y
    false

  serverTime: -> new Date().getTime() + (@serverTimeOffset || 0)


  # Given a board position, returns a list of [i,j] coordinates representing
  # orthagonally adjacent intersections
  get_adjacent_intersections: (i, j) ->
    neighbors = []
    if i > 0
      neighbors.push [i-1, j]
    if j < @size - 1
      neighbors.push [i, j+1]
    if i < @size - 1
      neighbors.push [i+1, j]
    if j > 0
      neighbors.push [i, j-1]
    neighbors

  # * Performs a breadth-first search about an (i,j) position to find recursively
  # * orthagonally adjacent stones of the same color (stones with which it shares
  # * liberties). Returns null for if there is no stone at the specified position,
  # * otherwise returns an object with two keys: "liberties", specifying the
  # * number of liberties the group has, and "stones", the list of [i,j]
  # * coordinates of the group's members.
  get_group: (i, j) ->
    color = @board[i][j]
    return null  if color is Go.EMPTY
    visited = {} # for O(1) lookups
    visited_list = [] # for returning
    queue = [[i, j]]
    count = 0
    while queue.length > 0
      stone = queue.pop()
      continue  if visited[stone]
      neighbors = @get_adjacent_intersections(stone[0], stone[1])
      _.each neighbors, (n) =>
        state = @board[n[0]][n[1]]
        count++  if state is Go.EMPTY
        if state is color
          queue.push [n[0], n[1]]
        return

      visited[stone] = true
      visited_list.push stone
    liberties: count
    stones: visited_list
