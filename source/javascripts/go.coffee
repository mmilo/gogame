# Game logic for the board game Go
class Go.Game extends Backbone.Firebase.Model

  initialize: (options) =>
    @size = options.size
    @last_move_passed = false
    @in_atari = false
    @attempted_suicide = false
    @played_moves = {}
    @firebase = "https://intense-fire-8240.firebaseio.com/#{options.game_id}"
    @board = @create_board(@size)
    @on('change:moves', (model) =>
      # Replay all the moves
      _.each(@get('moves'), (move, key, moves) =>
        # Skip moves that have already been played
        if @played_moves[key] == move
          console.log("not replaying move #{key}, (#{move[0]}, #{move[1]})")
        else
          if move == 'pass'
            @played_moves[key] = 'pass'
          else
            # Play the move in replay mode 
            @play(move[0], move[1], true)
      )
    )

  # Returns a size x size matrix with all entries initialized to Go.EMPTY
  create_board: (size) ->
    m = []
    i = 0
    while i < size
      m[i] = []
      j = 0
      while j < size
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
    _.keys(@played_moves).length

  # At any point in the game, a player can pass and let his opponent play
  pass: ->
    @end_game() if @last_move_passed
    @last_move_passed = true
    @store_move('pass')
    @played_moves = 'pass'
    return

  # Called when the game ends (both players passed)
  end_game: ->
    console.log "GAME OVER"
    return

  play: (i, j, replaying=false) =>
    console.log "Played at " + i + ", " + j
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
    @last_move_passed = false

    # Store the move unless we're replaying
    unless replaying
      @store_move([i,j])
    # Record that the move has been played
    @played_moves[@move_number()] = [i,j]

    @trigger('board_state_changed')
    true

  store_move: (move) ->
    moves = _.clone(@get('moves')) || {}
    moves[@move_number()] = move
    @set('moves', moves)

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
