pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timestamps()
    }

    parameters {
        string(name: 'NEXUS_URL', defaultValue: 'http://local-nexus:8081', description: 'Base URL of the Nexus server reachable from Jenkins.')
        string(name: 'NEXUS_RAW_REPOSITORY', defaultValue: 'mobile-apps', description: 'Nexus raw hosted repository used for APK publication.')
        string(name: 'DEV_OWNER_NAME', defaultValue: 'Navaa Tailors', description: 'Configured owner name for this dev APK.')
        string(name: 'DEV_SHOP_NAME', defaultValue: 'Digital Tailoring Studio', description: 'Configured shop name for this dev APK.')
        string(name: 'DEV_OWNER_PHONE', defaultValue: '9999999999', description: 'Owner login phone number for this dev APK.')
        string(name: 'DEV_SHOP_ADDRESS', defaultValue: 'Shop No. 12, Main Road, Near Landmark', description: 'Configured shop address for this dev APK.')
    }

    environment {
        APK_PATH = 'build/app/outputs/flutter-apk/app-dev-debug.apk'
        FLUTTER_BUILD_IMAGE = 'ghcr.io/cirruslabs/flutter:stable'
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }

        stage('Prepare Build') {
            steps {
                script {
                    env.APP_VERSION = sh(
                        returnStdout: true,
                        script: "awk -F': *' '/^version:/ { print \$2; exit }' pubspec.yaml"
                    ).trim()
                    if (!env.APP_VERSION) {
                        error('Unable to find the app version in pubspec.yaml.')
                    }
                }

                withCredentials([
                    string(
                        credentialsId: 'digital-tailoring-dev-owner-default-password',
                        variable: 'OWNER_DEFAULT_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu
                        mkdir -p config
                        python3 - <<'PY'
import json
import os
from pathlib import Path

Path('config/dev.json').write_text(json.dumps({
    'APP_ENV': 'dev',
    'SUPABASE_URL': '',
    'SUPABASE_PUBLISHABLE_KEY': '',
    'SESSION_TTL_DAYS': '7',
}, indent=2) + '\n', encoding='utf-8')
Path('config/owner.json').write_text(json.dumps({
    'OWNER_NAME': os.environ['DEV_OWNER_NAME'],
    'SHOP_NAME': os.environ['DEV_SHOP_NAME'],
    'OWNER_PHONE': os.environ['DEV_OWNER_PHONE'],
    'SHOP_ADDRESS': os.environ['DEV_SHOP_ADDRESS'],
    'OWNER_DEFAULT_PASSWORD': os.environ['OWNER_DEFAULT_PASSWORD'],
}, indent=2) + '\n', encoding='utf-8')
PY
                    '''
                }
            }
        }

        stage('Analyze And Build Dev APK') {
            steps {
                sh '''
                    set -eu
                    docker pull "$FLUTTER_BUILD_IMAGE"
                    docker run --rm \
                        --volumes-from local-jenkins \
                        --workdir "$WORKSPACE" \
                        "$FLUTTER_BUILD_IMAGE" \
                        sh -lc '
                            set -eu
                            flutter --version
                            flutter pub get
                            flutter analyze
                            flutter build apk --debug --flavor dev -t lib/main.dart \
                                --dart-define-from-file=config/dev.json \
                                --dart-define-from-file=config/owner.json
                        '
                '''
            }
        }

        stage('Publish To Nexus') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-admin',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu
                        test -f "$APK_PATH"
                        base_url="${NEXUS_URL%/}"
                        repository="$(printf '%s' "$NEXUS_RAW_REPOSITORY" | tr -d '/')"
                        test -n "$base_url"
                        test -n "$repository"
                        file_name="digital-tailoring-dev-${APP_VERSION}-build-${BUILD_NUMBER}.apk"
                        upload_url="$base_url/repository/$repository/digital-tailoring/dev/$APP_VERSION/$file_name"
                        curl --fail --show-error --silent \
                            --user "$NEXUS_USER:$NEXUS_PASSWORD" \
                            --upload-file "$APK_PATH" \
                            "$upload_url"
                        printf 'Published APK to %s\n' "$upload_url"
                    '''
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-dev-debug.apk', fingerprint: true
        }
        always {
            sh '''
                rm -f config/dev.json config/owner.json
            '''
        }
    }
}
