###* @jsx React.DOM ###
BoardIntersection = React.createClass
  handleClick: ->
    @props.onPlay() if @props.game.play(x: @props.row, y: @props.col)
    return

  render: ->
    classes = "point "
    unless @props.color is Go.EMPTY
      classes += "stone "
      classes += (if @props.color is Go.BLACK then "stone--black " else "stone--white ")
      classes += "stone--last" if @props.lastStone
    `<td onClick={this.handleClick} className={classes}></td>`

BoardRow = React.createClass
  render: ->
    `<tr className='row'>{this.props.intersections}</tr>`

BoardView = React.createClass
  render: ->
    rows = []
    i = 0

    while i < @props.game.size
      intersections = []
      j = 0

      lastStone = @props.game.lastStone()
      while j < @props.game.size
        intersections.push BoardIntersection(
          game: @props.game
          color: @props.game.board[i][j]
          row: i
          col: j
          onPlay: @props.onPlay
          lastStone: i == lastStone.x and j == lastStone.y
        )
        j++
      rows.push BoardRow(intersections: intersections)
      i++
    boardClass = "board turn turn--" + ((if @props.game.current_color() is Go.BLACK then "black" else "white"))
    `<div className='table'>
      <div className={boardClass}>
        <table className='grid'>
          {rows}
        </table>
      </div>
    </div>`

NewGameView = React.createClass
  handleClick: ->
    gameId = new Date().valueOf()
    window.location.replace("#{window.location.protocol}//#{window.location.host}/?g=#{gameId}")
    return
  render: ->
    `<input type="button" value="New Game" onClick={this.handleClick} />`

AlertView = React.createClass
  render: ->
    text = ""
    if @props.game.in_atari
      text = "ATARI!"
    else if @props.game.attempted_suicide
      text = "SUICIDE!"
    `<div id="alerts">{text}</div>`

PassView = React.createClass
  handleClick: (e) ->
    @props.game.play(pass: true)

  render: ->
    `<input className="btn-pass" type="button" value="Pass" onClick={this.handleClick} disabled={!this.props.enabled} />`

UserSessionView = React.createClass
  getInitialState: ->
    signingUp: false
    loggingIn: false

  logout: ->
    auth.logout()
    @setState(loggingIn: false, signingUp: false)

  loginWithTwitter: ->
    auth.login('twitter', {rememberMe: true})

  loginAnonymously: ->
    auth.login('anonymous', { rememberMe: true })

  signupWithEmail: ->
    @setState(signingUp: true, loggingIn: false)

  loginWithEmail: ->
    @setState(loggingIn: true, signingUp: false)

  cancelAction: ->
    @setState(loggingIn: false, signingUp: false)

  render: ->
    if !@props.has_authed
      `<span>loading</span>`
    else if @props.current_user?
      `<div>
        Logged in as &nbsp;
        <b>{this.props.current_user.displayName}</b>
        <input type="button" value="logout" onClick={this.logout} />
      </div>`
    else if @state.signingUp
      `<SignupAndLoginForm mode='signup' onCancel={this.cancelAction} />`
    else if @state.loggingIn
      `<SignupAndLoginForm mode='login'  onCancel={this.cancelAction} />`
    else
      `<div>
        <input type="button" value="Login with Twitter" onClick={this.loginWithTwitter} />
        <input type="button" value="Login with Email" onClick={this.loginWithEmail} />
        <input type="button" value="Login Anonymously" onClick={this.loginAnonymously} />
        <input type="button" value="Signup with email" onClick={this.signupWithEmail} />
      </div>`

SignupAndLoginForm = React.createClass
  getInitialState: ->
    state = {}
    state.email = ''
    state.password = ''
    state

  onChange: (e) ->
    state = {}
    state[$(e.target).attr('name')] = $(e.target).val()
    @setState(state)

  submitLogin: (email, password) ->
    auth.login('password', {email: email, password: password, rememberMe: true})

  handleSubmit: ->
    if @props.mode is 'signup'
      auth.createUser @state.email, @state.password, (error, user) =>
        return alert(error) if error
        @submitLogin(@state.email, @state.password)
    else
      @submitLogin(@state.email, @state.password)

  render: ->
    `<div>
      <a href="#" onClick={this.props.onCancel}>cancel</a>
      <input type="email" name="email" value={this.state.email} placeholder='Email address' onChange={this.onChange} />
      <input type="password" name="password" value={this.state.password} placeholder='Password' onChange={this.onChange} />
      <input type="button" value={this.props.mode == 'signup' ? "Sign up" : "Log In"} onClick={this.handleSubmit} />
    </div>`

PlayersView = React.createClass
  getInitialState: ->
    black_player: null
    white_player: null
    black_uid: null
    white_uid: null
    current_color: null
    player_times: @props.game.playerTimes()

  componentWillMount: ->
    @props.game.firebase.child('players').on 'value', (snapshot) =>
      players = snapshot.val() || {}

      if players[Go.BLACK] and not @state.black_player
        @observeUser(players[Go.BLACK], Go.BLACK)
      if players[Go.WHITE] and not @state.white_player
        @observeUser(players[Go.WHITE], Go.WHITE)

      @setState
        black_uid: players[Go.BLACK]
        white_uid: players[Go.WHITE]
        current_color: @props.game.current_color()

    @props.game.on 'board_state_changed', =>
      @setState
        current_color: @props.game.current_color()
        player_times: @props.game.playerTimes()

    # Update the game clock every second
    setInterval @updateClock, 1000

  updateClock: ->
    @setState player_times: @props.game.playerTimes()

  observeUser: (uid, color) ->
    @props.firebase.child('users').child(uid).on 'value', (snapshot) =>
      attrs = {}
      attrs["#{color}_player"] = snapshot.val()
      console.dir attrs
      @setState(attrs)

  joinGame: (color) ->
    if @props.current_user?
      @props.game.join(@props.current_user.uid, color)
    else
      return alert('You must log in to join the game')

  render: ->
    classes = "players turn--" + @state.current_color
    pass_button_enabled = !@props.game.game_is_over and (if @state.current_color is Go.WHITE then @props.current_user?.uid is @state.white_uid else @props.current_user?.uid is @state.black_uid)


    `<div className={classes}>
      <ul>
        { this.state.black_player ? 
          <PlayerView color={Go.BLACK} user={this.state.black_player} game={this.props.game} duration={this.state.player_times[Go.BLACK]} firebase={this.props.firebase} />
            :
          <PlayerSpotView color={Go.BLACK} joinGame={this.joinGame} />
        }
        { this.state.white_player ? 
          <PlayerView color={Go.WHITE} user={this.state.white_player} game={this.props.game} duration={this.state.player_times[Go.WHITE]} firebase={this.props.firebase} />
            :
          <PlayerSpotView color={Go.WHITE} joinGame={this.joinGame} />
        }
      </ul>
      {<PassView game={this.props.game} enabled={pass_button_enabled} />}
    </div>
    `


ContainerView = React.createClass
  getInitialState: ->
    game: null
    game_ready: false
    current_user: @props.environment.current_user
    open_games: {}
    open_games_ready: false
    has_authed: false

  componentWillMount: ->
    window.view = this
    @props.firebase = new Firebase("https://intense-fire-8240.firebaseio.com/")
    

    # TODO: scope auth properly and make it availabel to ancestor views
    window.auth = new FirebaseSimpleLogin @props.firebase, (error, user) =>
      if user
        currentUserRef = @props.firebase.child('users').child(user.uid)
        currentUserRef.on 'value', (snap) =>
          # Update our local version
          storedUser = snap.val()
          Go.current_user = storedUser
          Go.trigger('change:current_user')
          @setState(current_user: storedUser, has_authed: true)

          # Fill out any missing attributes
          userAttrs = _.pick(storedUser, 'uid', 'displayName', 'provider', 'username')
          defaultedAttributes = _.defaults(_.clone(userAttrs), { displayName: 'Anonymous', username: 'unknown' })
          unless _.isEqual(userAttrs, defaultedAttributes)
            currentUserRef.update(defaultedAttributes)

        # Manage online state
        @props.firebase.child('.info/connected').on 'value', (snap) =>
          if snap.val() is true
            # Get a ref for a new connection
            con = @props.firebase.child('presence').child(user.uid).push()
            # Set the onDisconnect handling
            con.onDisconnect().remove()
            currentUserRef.child('lastOnline').onDisconnect().set(Firebase.ServerValue.TIMESTAMP)
            # Then (and only then to avoid races) set the connection
            con.set(true)

      else if error
        @setState has_authed: true
        alert error.message
    
    if (gameId = getParameterByName('g'))?
      window.game = new Go.Game({ size: 19, game_id: gameId })
      @setState(game: game)
      game.once 'ready', => @setState game_ready: true
      game.firebase.child('moves').on 'value', @onGameUpdate
    else
      @props.firebase.child('games').startAt(Go.STATUS.WAITING).endAt(Go.STATUS.WAITING).on 'value', (snapshot) =>
        @setState(open_games: snapshot.val() || {})
        @setState(open_games_ready: true)

    @props.environment.on 'change:current_user', => @setState(current_user: @props.environment.current_user)

  onGameUpdate: ->
    @setState game: @state.game
    return

  render: ->
    if @state.game?
      if @state.game_ready
        body =  `
          <div>
            <div className="game-controls">
              <PlayersView game={this.state.game} current_user={this.state.current_user} firebase={this.props.firebase} />
              <AlertView game={this.state.game} />
            </div>
            <div className="game-board">
              <BoardView game={this.state.game} onPlay={this.onGameUpdate} />
            </div>
          </div>`
      else
        'loading game...'
    else if !!_.keys(@state.open_games).length
      games = []
      _.each @state.open_games, (game, id) ->
        path = "/?g=#{id}"
        games.push `<li><a href={path}> game {id}</a> </li>`
      body = `
        <ul>
          {games}
        </ul>`
    else if @state.open_games_ready
      body = "Looks like there aren't any open games."
    else
      body = 'loading games...'

    return `<div>
      <div id='header'>
        <div className='navigation'>
          <a href="/">List games</a>
          &nbsp;
          &nbsp;
          &nbsp;
          <NewGameView />
          &nbsp;
          &nbsp;
          &nbsp;
          <PlayersOnlineView firebase={this.props.firebase} />
        </div>
        <div className='user-session'>
          <UserSessionView has_authed={this.state.has_authed} current_user={this.state.current_user} />
        </div>
      </div>
      <div id='body'>
        { body }
      </div>
    </div>`

PlayersOnlineView = React.createClass
  getInitialState: ->
    players_online_count: 'loading'

  componentWillMount: ->
    @props.firebase.child('presence').on 'value', (snap) =>
      @setState players_online_count: _.keys(snap.val() || {}).length

  render: ->
    `<span>{this.state.players_online_count} players online</span>`


React.renderComponent `<ContainerView environment={Go} />`, document.getElementById("main")
