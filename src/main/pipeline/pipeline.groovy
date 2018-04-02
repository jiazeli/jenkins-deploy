#!/usr/bin/env groovy
package pipeline

// some config for diff project
class Config {
    public static String DEPLOY_REMOTE_USER = "spec"
    public static String DEPLOY_REMOTE_HOST_PORT = "22"
    // internal private project for security info
    public static String PROJECT_OSS_INTERNAL = "ssh://git@gitlab.td.internal:20022/home1-oss/oss-internal.git"
    // 项目部署用相关信息
    public static String APP_DEPLOY = "ssh://git@gitlab.td.internal:20022/SPEC/muji-apama-deploy.git"
    public static String APP_DEPLOY_BRANCH = "develop"
    // 全局的共享库
    public static String WGL_LIBRARIES = "ssh://git@gitlab.td.internal:20022/home1-oss/jenkins-wgl.git"
    // config global credentials in jenkins with admin role,and define credentialsId with this
    public static String JENKINS_CREDENTIALS_ID = "global_key"
    public static String NODE_LABEL = "spec"
    public static String DEF_PROJEVT_VERSION = "1.1.0-SNAPSHOT"
    public static String DEF_WORK_DIR = "~/ws"

}

// 加载公共的pipeline 类库 ,包含 Deploy.groovy Utilities.groovy
library identifier: 'jenkins-wgl@master',
        retriever: modernSCM([$class: 'GitSCMSource', remote: "${Config.WGL_LIBRARIES}", credentialsId: "${Config.JENKINS_CREDENTIALS_ID}"])

def project

// 初始化阶段
stage("初始化") {
    node() {
        timestamps {
            step([$class: 'WsCleanup'])
            sh "ls -la ${pwd()}"
            git branch: "${Config.APP_DEPLOY_BRANCH}",credentialsId: "${Config.JENKINS_CREDENTIALS_ID}", url: "${Config.APP_DEPLOY}"

            def workspace = pwd()
            project = Utilities.getProjectList("${workspace}")
            echo "project is : ${project}"
        }
    }
}

// 收集参数
stage "参数采集"
def paramMap = [:]
timeout(30) { // 超时30分钟
    timestamps {
        paramMap = input id: 'Environment_id', message: 'Custome your parameters', ok: '提交', parameters:
                Utilities.getInputParam(project, Config.DEF_PROJEVT_VERSION)
        println("param is :" + paramMap.inspect())
    }
}

stage("资源准备") {
    node() {
        timestamps {
            if (fileExists("${paramMap.PROJECT}")) {
                echo "stash project: ${paramMap.PROJECT}"
                def envJson = readFile file: "${workspace}/${paramMap.PROJECT}/environments/environment.json"
                paramMap = Utilities.generateParam(paramMap, envJson)
                privateConfig(paramMap)

                // 认证信息默认从当前部署项目获取,获取不到的情况再从oss-internal统一的地方获取
                if (fileExists("src/main/credentials/${paramMap.ENV}/id_rsa")) {
                    dir("src/main/credentials/${paramMap.ENV}/") {
                        stash name: "id_rsa", includes: "id_rsa"
                    }
                } else {
                    git credentialsId: "${Config.JENKINS_CREDENTIALS_ID}", branch: 'develop', url: "${Config.PROJECT_OSS_INTERNAL}"
                    // stash resources for the moment
                    dir("src/main/jenkins/") {
                        if (paramMap.ENV != null && fileExists("${paramMap.ENV}/id_rsa")) {
                            dir("${paramMap.ENV}") {
                                stash name: "id_rsa", includes: "id_rsa"
                            }
                        } else if (fileExists("id_rsa")) {
                            stash name: "id_rsa", includes: "id_rsa"
                        } else {
                            print("none credentials in remote ${Config.PROJECT_OSS_INTERNAL},please check that!!")
                        }
                    }
                }
                // 从nexus下载构建产物
                def fileName = DeployUtil.downloadArtifact(paramMap, "${workspace}/${paramMap.PROJECT}")
                paramMap.ARTIFACT_NAME = "${fileName}".toString()
                stash name: "${paramMap.PROJECT}", includes: "${paramMap.PROJECT}/**/*"

                // 参数做持久化保存
                writeFile(file: 'data.zip', text: paramMap.inspect(), encoding: 'utf-8')
                stash "data.zip"
            } else {
                print("project: ${paramMap.PROJECT} in ${Config.APP_DEPLOY} is not exist, please check for that!!")
            }
            sh "ls -la ${pwd()}"
        }
    }
}

stage("预部署") {
    node() {
        timestamps {
            step([$class: 'WsCleanup'])
            unstash "id_rsa"
            sh "chmod +r id_rsa"

            unstash "data.zip"

            def data = readFile encoding: 'utf-8', file: 'data.zip'
            echo "data:" + data
            paramMap = Eval.me(data)

            def preBranches = [:]
            echo "--------------PreDeploy start--------------- "
            for (int i = 0; i < paramMap["PRE_NODES"].size(); i++) {
                def ipNode = paramMap["PRE_NODES"][i]
                preBranches[paramMap.PROJECT + "@" + ipNode] = Utilities.generateBranch(paramMap, ipNode)
            }
            echo "the projects which is waiting to be deployed are : ${preBranches}"
            parallel preBranches
        }
    }
}

stage "前置校验"
if (paramMap.NODES.size() > 0) {
// 暂停,等待验证,
    timeout(30) {
        timestamps {
            input id: 'VerifyPreNode_id', message: "请验证前置节点:${paramMap["PRE_NODES"]}服务是否成功部署,确认OK可继续部署", ok: '继续部署'
            //todo do rollback action
        }
    }
} else {
    println("单节点部署,pipeline跳过等待验证环节.")
}

stage("部署全部") {
    node() {
        timestamps {
            if (paramMap.NODES.size() > 0) {
                def parallelBranches = [:]
                echo "--------------Deploy start--------------- "
                for (int i = 0; i < paramMap["NODES"].size(); i++) {
                    def ipNode = paramMap["NODES"][i]
                    parallelBranches[paramMap.PROJECT + "@" + ipNode] = Utilities.generateBranch(paramMap, ipNode)
                }
                echo "waiting deploy projects are : ${parallelBranches}"
                parallel parallelBranches
            }
        }
    }
}

stage("完成") {
    echo "--------------Deploy Success--------------- "
//    mail bcc: '', body: 'test for jenkins!!!', cc: '2075@forex.com.cn', from: '', replyTo: '', subject: 'Deploy ' +
//            'success', to: '2074@forex.com.cn'

}

/**
 * 不同项目特有的定制参数
 * @param paramMap
 * @return
 */
def privateConfig(paramMap) {
    paramMap.DEPLOY_USER = Config.DEPLOY_REMOTE_USER
    paramMap.WORK_DIR = Config.DEF_WORK_DIR
}