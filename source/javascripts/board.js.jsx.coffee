###* @jsx React.DOM ###
BoardIntersection = React.createClass
  handleClick: ->
    @props.onPlay() if @props.game.play([@props.row, @props.col])
    return

  render: ->
    classes = "point "
    classes += (if @props.color is Go.BLACK then "stone stone--black" else "stone stone--white")  unless @props.color is Go.EMPTY
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

      while j < @props.game.size
        intersections.push BoardIntersection(
          game: @props.game
          color: @props.game.board[i][j]
          row: i
          col: j
          onPlay: @props.onPlay
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
    @props.game.play('pass')

  render: ->
    `<input id="pass-btn" type="button" value="Pass" onClick={this.handleClick} />`

UserSessionView = React.createClass
  getInitialState: ->
    signingUp: false
    loggingIn: false

  logout: ->
    auth.logout()
    @setState(loggingIn: false, signingUp: false)

  loginWithTwitter: ->
    auth.login('twitter', {rememberMe: true})

  signupWithEmail: ->
    @setState(signingUp: true, loggingIn: false)

  loginWithEmail: ->
    @setState(loggingIn: true, signingUp: false)

  render: ->
    if @props.current_user?
      `<div>
        Logged in as: {this.props.current_user.uid}
        <input type="button" value="logout" onClick={this.logout} />
      </div>`
    else if @state.signingUp
      `<SignupAndLoginForm mode='signup' />`
    else if @state.loggingIn
      `<SignupAndLoginForm mode='login' />`
    else
      `<div>
        <input type="button" value="Login with Twitter" onClick={this.loginWithTwitter} />
        <input type="button" value="Login with Email" onClick={this.loginWithEmail} />
        <input type="button" value="Signup with email" onClick={this.signupWithEmail} />
      </div>`

SignupAndLoginForm = React.createClass
  getInitialState: ->
    state = {}
    state.email = if @props.mode is 'signup' then "t-#{new Date().valueOf()}@gamilis.com" else ''
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
      {this.props.mode}:
      <input type="text" name="email" value={this.state.email} placeholder='you@email.com' onChange={this.onChange} />
      <input type="password" name="password" value={this.state.password} placeholder='password' onChange={this.onChange} />
      <input type="button" value="submit" onClick={this.handleSubmit} />
    </div>`

PlayersView = React.createClass
  componentWillMount: ->
    @props.game.on('change:players', =>
      @setState(game: @props.game)
    )

  handleClick: ->
    console.log "Joining!"
    if !@props.current_user?
      alert('You must log in to join the game')
      return false

    # Take the first available spot
    if @props.game.join(@props.current_user.uid)
      @props.onPlayerAdd()
    else
      alert("Sorry, there isn't place available for you in this game.")

  render: ->
    player1 = @props.game.players()[Go.BLACK]
    player2 = @props.game.players()[Go.WHITE]

    `<div className='players'>
      <p className={player1 ? '' : 'waiting'}>{player1 ? player1 : 'waiting for player 1 to join...'}</p>
      <p className={player2 ? '' : 'waiting'}>{player2 ? player2 : 'waiting for player 2 to join...'}</p>
      {!player1 || !player2 ? <input id="join-btn" type="button" value="Join" onClick={this.handleClick} /> : ''}
    </div>
    `


ContainerView = React.createClass
  getInitialState: ->
    game: @props.game
    current_user: @props.environment.current_user

  componentWillMount: ->
    @props.game.on 'board_state_changed', =>
      @setState(game: @props.game)
    @props.environment.on 'change:current_user', =>
      @setState(current_user: @props.environment.current_user)

  onGameUpdate: ->
    @setState game: @props.game
    return

  render: ->
    `<div>
      <UserSessionView current_user={this.state.current_user} />
      <hr />
      <NewGameView />
      <AlertView game={this.state.game} />
      <PlayersView game={this.state.game} onPlayerAdd={this.onGameUpdate} current_user={this.state.current_user} />
      <BoardView game={this.state.game} onPlay={this.onGameUpdate} />
      <PassView game={this.state.game} />
    </div>`


chatRef = new Firebase("https://intense-fire-8240.firebaseio.com/")
auth = new FirebaseSimpleLogin(chatRef, (error, user) ->
  Go.current_user = user
  Go.trigger('change:current_user')
)


gameId = getParameterByName('g')
if gameId?
  window.game = new Go.Game({}, { size: 19, game_id: gameId })
  game.once 'sync', -> React.renderComponent `<ContainerView game={game} environment={Go} />`, document.getElementById("main")
else
  React.renderComponent `<NewGameView />`, document.getElementById("main")

