do(
  React = require 'react'
) ->

  {div} = React.DOM

  Jumbotron = React.createClass
    propTypes:
      fullWidth: React.PropTypes.bool

    getDefaultPropTypes:
      fullWidth: true

    render: ->
      if @props.fullWidth
        div className: 'jumbotron',
          div className: 'container',
            @props.children
      else
        div className: 'jumbotron',
          @props.children

  module.exports = Jumbotron
