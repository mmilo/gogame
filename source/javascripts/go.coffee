# Game logic for the board game Go
class Go.Game extends Backbone.Model
  constructor: (options) ->
    @size = options.size
    @resetBoard()

    @firebase = new Firebase("https://intense-fire-8240.firebaseio.com/games/#{options.game_id}")

    @firebase.child('players').on 'value', (snapshot) =>
      @players = snapshot.val() || {}

    @firebase.child('moves').on 'value', (snapshot) =>
      moves = snapshot.val()
      try
        unless moves?
          throw("Firebase thinks there are no moves. Rollback")
        if @accepted_moves.length > _.keys(moves).length
          throw("Firebase rejected a move - rollback")

        # Play / replay moves
        _.each moves, (move, key, moves) =>
          debugger
          # Skip moves that have already been played
          if _.isEqual(@accepted_moves[move.index], move)
            console.log("Not replaying move ##{move.index}, (#{move[0]}, #{move[1]})")
          else if @accepted_moves[move.index]?
            throw("Conflict in moves - Start over")
          else
            # Replay the new move
            @play(move, replaying: true)
       
      catch error
        console.log "ERROR: #{error}"
        # Start fresh and replay all the moves
        @resetBoard()
        _.each moves, (move, key, moves) => @play(move, replaying: true)

  resetBoard: =>
    @in_atari = false
    @attempted_suicide = false
    @accepted_moves = []
    @board = @create_board()
    @trigger('board_state_changed')

  join: (userId) =>
    if !@players[Go.BLACK]?
      @firebase.child('players').child(Go.BLACK).set(userId)
      return true
    else if !@players[Go.WHITE]?
      @firebase.child('players').child(Go.WHITE).set(userId)
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

  # Called when the game ends (both players passed)
  end_game: ->
    console.log "GAME OVER"
    return

  play: (move, options={}) =>
    console.log "#{if options.replaying then 'Re-' else ''}Played new move at " + move[0] + ", " + move[1]

    # Only permit each player to take their own turn
    if !options.replaying and @players[@current_color()] isnt Go.current_user.uid
      console.warn "Ignoring move played out of turn."
      return false

    if move is 'pass'
      @end_game() if @accepted_moves[@move_number()-1] is 'pass'
      @accept_move('pass', options.replaying)
      return true
    else if move[0]? and move[1]?
      i = move[0]
      j = move[1]
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
        @board[stone[0]][stone[1]] = Go.EMPTY
        return

      return

    @in_atari = true  if atari

    # Store the move unless we're replaying
    @accept_move([i,j], options.replaying)

    @trigger('board_state_changed')
    true

  accept_move: (move, replaying=false) ->
    # Set the numerical index of the move on it for storage
    move.index = @move_number()
    # Register that it's been played at that index in the @accepted_moves
    @accepted_moves[move.index] = move
    # Store it in Firebase
    @firebase.child('moves').push(move) unless replaying

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
