folder('python-pipelines') {
    description('Python pipelines')
}

pipelineJob('python-pipelines/hello-world') {
    definition {
        cps {
            script(readFileFromWorkspace('pipelines/hello-world.js'))
            sandbox()
        }
    }
}