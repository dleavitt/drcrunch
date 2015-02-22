#= require angular/angular
#= require angular-ui-bootstrap-bower/ui-bootstrap
#= require ng-file-upload/angular-file-upload

#= require_tree ./partials

angular
  .module 'DrCrunch', ['ui.bootstrap', 'angularFileUpload']
  
  .run ($templateCache) ->
    for path, partial of JST
      prettyPath = path.split('/').slice(1) + '.html'
      console.log "Added #{prettyPath} to $templateCache"
      $templateCache.put prettyPath, partial()
  
  .controller 'AppCtrl', ($scope, $upload, $http) ->
    $scope.compression = 
      advpng: false
      pngquant:
        quality_min: 80
        quality_max: 90
      jpegrecompress: 
        quality: 3
      jpegoptim: 
        max_quality: 90
      advpng: false
      optipng: false

    $scope.$watch 'files', (newFile, oldFile) ->
      return unless $scope.files?.length
      uploadFile(file) for file in $scope.files

    $scope.crunch = (image) ->
      console.log $scope.compression
      $http.put("/api/images/#{image.id}/crunch", compression: $scope.compression)
        .then (res) ->
          image.file.images.push(res.data)

    uploadFile = (file) ->
      $upload.upload(url: '/api/images', file: file)
        .progress (e) ->
          console.log e.loaded, e.total
        .success (data, status, headers, config) ->
          console.log(file)
          data.original = true
          data.file = file
          file.images = [data]





