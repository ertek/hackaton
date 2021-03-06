# Creado por Jorge Cedi Voirol el 13 de Febrero del 2015
# Opciones
# width
# height
# url
# yourPositionMarker
# pinsImage
# centerPin
require [
  "handlebars",
  "jquery",
  "jquery-cookie",
  "underscore",
  "backbone",
  "geoPosition",
  "async!http://maps.google.com/maps/api/js?key=AIzaSyCczG2v_nYfo0BQfxcxrf_DTKhjTqQJpfo&sensor=false&v=3"],  (Handlebars) ->

  namespace = "Mapas"
  class MarkerModel extends  Backbone.Model
    initialize: ->
      return

  class MarkerList extends Backbone.Collection
    model: MarkerModel
    parse: (data)->
        if data.features
            return data.features
        else
            return data
    initialize: (opts)->
      if opts
        if opts.url
          @url = opts.url
    comparator: (marker)->
      marker.get 'id'


  class MapView extends Backbone.View
    # Inician opciones de la aplicación
    el: $ '#map'
    center: null
    map_id: "#my_map"
    map: null
    width: '100%'
    height: '100%'
    markers: []
    centerMarker: null
    bounds: null
    opts: {}


    storedPosition: ->
      lat = $.cookie 'lat'
      lng = $.cookie 'lng'
      if lat and lng
        return {lat, lng}
      else
        return false

    # Método de inicialización, agrega opciones a la aplicación
    initialize: (opts)->
      if opts
        @opts = opts
        if opts.width
          @width = opts.width
        if opts.height
          @height = opts.height
      else
        opts = {}

      if @storedPosition()
        @center = @storedPosition()
        if $(@el).length
          @render(opts)
      else
        @getBrowserGeolocation()


    # Renderiza html y mapa
    render: (opts)->
      # Creamos div para el mapa
      $(@el).append "<div id='#{@map_id}' style='width: #{@width}; height: #{@height};'></div>"
      # Opciones básicas del mapa
      map_options =
        zoom: 12
        center: new google.maps.LatLng @center.lat, @center.lng
      # Se crea el mapa y se agrega al dic creado anteriormente
      @map = new google.maps.Map document.getElementById(@map_id), map_options
      @bounds = new google.maps.LatLngBounds()
      if opts.yourPositionMarker == true
        @setCenterMarker(new google.maps.LatLng(@center.lat, @center.lng), opts.centerPin)
      if opts.url
        @fetchMarkers(opts.url, opts.pinsImage, opts.pinsBigImage)

    setCenterMarker: (position, pinImage)->
      @centerMarker = new google.maps.Marker
        position: position
        map: @map
        icon: pinImage
        title: "Mi posición"
      @bounds.extend @centerMarker.getPosition()

    fetchMarkers: (url, pinsImage = null, pinsBigImage = null)->
      list = new MarkerList({
        url: url
      })
      self = @
      list.fetch
        success: ->
          infowindow = null
          $("#lista").html(null)
          $("#loading").hide()
          list.forEach (m, i)->
            if m.get('geometry') or m.get('ubicacion')
                marker_id = m.get('id') or m.get('pk')
                #console.log m.get('geometry')
                lat = 0
                lng = 0
                if m.get 'geometry'
                    lat = m.get('geometry')['coordinates'][1]
                    lng = m.get('geometry')['coordinates'][0]
                if m.get 'ubicacion'
                    lat = m.get('ubicacion')['coordinates'][1]
                    lng = m.get('ubicacion')['coordinates'][0]
                #console.log lat,lng
                self.markers[marker_id] = new google.maps.Marker
                  position: new google.maps.LatLng lat, lng
                  map: self.map
                  title: "H",
                  icon: pinsImage

                nombre = ""
                domicilio = ""
                if m.get 'properties'
                    nombre = m.get('properties').nombre
                    domicilio = m.get('properties').domicilio
                else
                    nombre = m.get('nombre')
                    domicilio = m.get('domicilio')
                $("#lista").append('<div id="list_item_' + marker_id + '" class="ubicacion card-header"> <b>' + nombre + '</b> <p>Domicilio: ' + domicilio + '</p></div>')
                $("#list_item_" + marker_id ).on 'mouseover',(evt)->
                    if infowindow.getMap() == null or !infowindow
                        self.markers[marker_id].setIcon pinsBigImage

                $("#list_item_" + marker_id ).on 'mouseout',(evt)->
                    if infowindow.getMap() == null or !infowindow
                        self.markers[marker_id].setIcon pinsImage

                $("#list_item_" + marker_id ).on 'click',(evt)->
                    if infowindow
                      infowindow.close()

                    infowindow = new google.maps.InfoWindow
                      content: contentString
                      disableAutoPan: false


                    infowindow.open self.map, self.markers[marker_id]
                    last_model = m
                    return
                #console.log $("#lista")

                if self.opts.popupTemplate
                  template = Handlebars.compile(self.opts.popupTemplate)
                  contentString = template({m:m})
                  #console.log m

                  google.maps.event.addListener self.markers[marker_id], 'click', ->
                    if infowindow
                      infowindow.close()
                    #markers[business.get 'id'].setIcon regularBigPin
                    #infowindow = new google.maps.InfoWindow
                    #	content: contentString

                    infowindow = new google.maps.InfoWindow
                      content: contentString
                      disableAutoPan: false


                    infowindow.open self.map, self.markers[marker_id]
                    last_model = m
                    return

                self.bounds.extend self.markers[marker_id].getPosition()
          console.log self.markers
          self.map.fitBounds(self.bounds)

    # Obtiene ubicación mediante la biblioteca geoposition.js y la guarda en cookies y en la instancia de la aplicación
    getBrowserGeolocation: ->
      if geoPosition.init()
        geoPosition.getCurrentPosition @storePosition, @geolocationErrorCallback
      else
        console.log "Error al localizar"

    # Obtiene ubicación guardada en las cookies


    # Guarda la ubicación en las cookies
    storePosition: (position)->
      # TODO: Guardar la info de forma segura
      $.cookie 'lat', position.coords.latitude
      $.cookie 'lng', position.coords.longitude
      console.log @
      window.map_view.center =
        'lat': position.coords.latitude,
        'lng': position.coords.longitude
      window.map_view.render(window.map_view.opts)

    # Método de error para geoubicación
    geolocationErrorCallback: (err)=>
      if err.code == 1
        console.log "Denied by user."
        position =
            coords:
                latitude : -28.4601593
                longitude: -65.7642746
        @storePosition position


  # Inicia la aplicación
  window.MapView = MapView
  load_app()
