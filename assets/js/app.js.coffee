#= require angular/angular
#= require angular-ui-bootstrap-bower/ui-bootstrap-tpls
#= require ng-file-upload/angular-file-upload
#= require angular-rangeslider

#= require_tree ./partials

angular
  .module 'DrCrunch', ['ui.bootstrap', 'angularFileUpload']
  
  .run ($templateCache) ->
    for path, partial of JST
      prettyPath = path.split('/').slice(1) + '.html'
      console.log "Added #{prettyPath} to $templateCache"
      $templateCache.put prettyPath, partial()
  
  .controller 'AppCtrl', ($scope, $upload, $http, $modal) ->
    $scope.compression = 
      advpng:
        enabled: false
        level: 4
      gifsicle:
        enabled: true
        level: 3
      jpegoptim: 
        enabled: true
        max_quality: 90
      jpegrecompress: 
        enabled: false
        quality: 3
      jpegtran:
        enabled: false
        copy_chunks: false
        progressive: true
        jpegrescan: false
      optipng:
        enabled: false
        level: 6
        interlace: false
      pngcrush:
        enabled: false
        chunks: 'alla'
        fix: false
        brute: false
        blacken: true
      pngout:
        enabled: false
        copy_chunks: false
        strategy: 0
      pngquant:
        enabled: true
        quality_min: 80
        quality_max: 90
        speed: 3

    $scope.compressionOptions = 
      advpng: level: [0, 4]
      gifsicle: level: [1,3]
      pngquant: 
        quality_min: [0,100]
        quality_max: [0,100]
        speed: [1,11]
      jpegoptim:
        level: [0,100]
      jpegrecompress:
        quality: [0,3]
      optipng:
        level: [0,7]
      pngcrush:
        chunks: ['alla', 'allb']
      pngout:
        strategy: [
          [0, 'Extreme']
          [1, 'Intense']
          [2, 'Longest Match']
          [3, 'Huffman Only']
          [4, 'Uncompressed']
        ]

    $scope.$watch 'compression.pngout.strategy', ->
      console.log($scope.compression.pngout.strategy)


    $scope.$watch 'files', (newFile, oldFile) ->
      return unless $scope.files?.length
      uploadFile(file) for file in $scope.files

    $scope.crunch = (image) ->
      console.log $scope.compression
      $http.put("/api/images/#{image.id}/crunch", compression: $scope.compression)
        .then (res) ->
          image.file.images.push(res.data)

    $scope.showCompressionSettings = (image) ->
      $modal.open
        controller: 'CompressionSettingsCtrl'
        templateUrl: 'compression_settings.html'
        size: 'lg'
        resolve:
          image: -> image

    uploadFile = (file) ->
      $upload.upload(url: '/api/images', file: file)
        .progress (e) ->
          console.log e.loaded, e.total
        .success (data, status, headers, config) ->
          console.log(file)
          data.original = true
          data.file = file
          file.images = [data]
  .controller 'CompressionSettingsCtrl', ($scope, $modalInstance, image) ->
    $scope.image = image


  .directive 'slider', ->
    restrict: 'E'
    templateUrl: 'slider.html'
    scope:
      name: '@'
      model: '=ngModel'
      range: '='

  .directive 'compressionGroup', ->
    restrict: 'E'
    templateUrl: 'compression_group.html'
    transclude: true
    scope:
      name: '@'
      model: '=ngModel'
    

  # .directive 'showErrors', ->
  #   restrict: 'A'

  #   link: (scope, el, attrs, formCtrl) ->
  #     input = el.find('input')
  #     input.bind 'change', ->
  #       el.toggleClass 'has-error', input.hasClass('ng-invalid')

