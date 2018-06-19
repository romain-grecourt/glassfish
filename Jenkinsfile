// list of test ids
def jobs = ["embedded_all", "jdbc_all", "webservice_all", "ql_gf_embedded_profile_all", "nucleus_admin_all", "naming_all", "ejb_timer_cluster_all", "web_all", "security_all","connector_all"]

def parallelStagesMap = jobs.collectEntries {
  ["${it}": generateStage(it)]
}

def generateStage(job) {
    return {
        def label = "mypod-A"
        podTemplate(label: label) {
            node(label) {
                stage("${job}") {
                    container('glassfish-ci') {
                      checkout scm
                      unstash 'build-bundles'
                      sh "${WORKSPACE}/appserver/tests/gftest.sh run_test ${job}"
                      archiveArtifacts artifacts: "${job}-results.tar.gz"
                      junit testResults: 'results/junitreports/*.xml', allowEmptyResults: true
                    }
                }
            }
        }
    }
}

pipeline {
  options {
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  agent {
    kubernetes {
      label 'mypod'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
       claimName: maven-repo
  hostAliases:
  - ip: "127.0.0.1"
    hostnames:
    - "localhost.localdomain"
  containers:
  - name: glassfish-ci
    image: arindamb/glassfish-ci
    command:
    - cat
    tty: true
    imagePullPolicy: Always
    volumeMounts:
        - mountPath: "/root/.m2/repository"
          name: maven-repo
"""
    }
  }
  environment {
    S1AS_HOME = "${WORKSPACE}/glassfish5/glassfish"
    APS_HOME = "${WORKSPACE}/main/appserver/tests/appserv-tests"
    TEST_RUN_LOG = "${WORKSPACE}/tests-run.log"
    MAVEN_REPO_LOCAL = "/root/.m2/repository"
  }
  stages {
    stage('glassfish-build') {
      agent {
        kubernetes {
          label 'mypod-A'
        }
      }
      steps {
        container('glassfish-ci') {
          sh 'ci/build-tools/glassfish/gfbuild.sh build_re_dev 2>&1'
          archiveArtifacts artifacts: 'bundles/*.zip'
          junit testResults: 'test-results/build-unit-tests/results/junitreports/test_results_junit.xml'
          stash includes: 'bundles/*', name: 'build-bundles'
        }
      }
    }
    stage('glassfish-tests') {
      steps {
        script {
          parallel parallelStagesMap
        }
      }
    }
  }
}