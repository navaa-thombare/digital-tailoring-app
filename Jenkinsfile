pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
        timestamps()
    }

    parameters {
        string(name: 'NEXUS_URL', defaultValue: 'http://localhost:8081', description: 'Base URL of the Nexus server.')
        string(name: 'NEXUS_RAW_REPOSITORY', defaultValue: 'mobile-apps', description: 'Nexus raw hosted repository used for APK publication.')
        string(name: 'DEV_OWNER_NAME', defaultValue: 'Navaa Tailors', description: 'Configured owner name for this dev APK.')
        string(name: 'DEV_SHOP_NAME', defaultValue: 'Digital Tailoring Studio', description: 'Configured shop name for this dev APK.')
        string(name: 'DEV_OWNER_PHONE', defaultValue: '9999999999', description: 'Owner login phone number for this dev APK.')
        string(name: 'DEV_SHOP_ADDRESS', defaultValue: 'Shop No. 12, Main Road, Near Landmark', description: 'Configured shop address for this dev APK.')
    }

    environment {
        APK_PATH = 'build/app/outputs/flutter-apk/app-dev-debug.apk'
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
                    env.APP_VERSION = powershell(
                        returnStdout: true,
                        script: '''
                            $line = Select-String -Path 'pubspec.yaml' -Pattern '^version:\\s*(.+)$'
                            if ($null -eq $line) {
                                throw 'Unable to find the app version in pubspec.yaml.'
                            }
                            $line.Matches[0].Groups[1].Value.Trim()
                        '''
                    ).trim()
                }

                withCredentials([
                    string(
                        credentialsId: 'digital-tailoring-dev-owner-default-password',
                        variable: 'OWNER_DEFAULT_PASSWORD'
                    )
                ]) {
                    powershell '''
                        $ErrorActionPreference = 'Stop'
                        New-Item -ItemType Directory -Path 'config' -Force | Out-Null

                        $dev = [ordered]@{
                            APP_ENV = 'dev'
                            SUPABASE_URL = ''
                            SUPABASE_PUBLISHABLE_KEY = ''
                            SESSION_TTL_DAYS = '7'
                        }
                        $owner = [ordered]@{
                            OWNER_NAME = $env:DEV_OWNER_NAME
                            SHOP_NAME = $env:DEV_SHOP_NAME
                            OWNER_PHONE = $env:DEV_OWNER_PHONE
                            SHOP_ADDRESS = $env:DEV_SHOP_ADDRESS
                            OWNER_DEFAULT_PASSWORD = $env:OWNER_DEFAULT_PASSWORD
                        }

                        $dev | ConvertTo-Json | Set-Content -Path 'config/dev.json' -Encoding UTF8
                        $owner | ConvertTo-Json | Set-Content -Path 'config/owner.json' -Encoding UTF8
                        flutter pub get
                    '''
                }
            }
        }

        stage('Analyze') {
            steps {
                powershell 'flutter analyze'
            }
        }

        stage('Build Dev APK') {
            steps {
                powershell '.\\tool\\build_dev.ps1'
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
                    powershell '''
                        $ErrorActionPreference = 'Stop'
                        if (-not (Test-Path -LiteralPath $env:APK_PATH)) {
                            throw "APK was not generated at $env:APK_PATH."
                        }

                        $baseUrl = $env:NEXUS_URL.TrimEnd('/')
                        $repository = $env:NEXUS_RAW_REPOSITORY.Trim('/')
                        if ([string]::IsNullOrWhiteSpace($baseUrl) -or [string]::IsNullOrWhiteSpace($repository)) {
                            throw 'NEXUS_URL and NEXUS_RAW_REPOSITORY are required.'
                        }

                        $fileName = "digital-tailoring-dev-$env:APP_VERSION-build-$env:BUILD_NUMBER.apk"
                        $uploadUrl = "$baseUrl/repository/$repository/digital-tailoring/dev/$env:APP_VERSION/$fileName"
                        & curl.exe --fail --show-error --silent --user "${env:NEXUS_USER}:${env:NEXUS_PASSWORD}" --upload-file $env:APK_PATH $uploadUrl
                        if ($LASTEXITCODE -ne 0) {
                            throw "Nexus upload failed with exit code $LASTEXITCODE."
                        }
                        Write-Host "Published APK to $uploadUrl"
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
            powershell '''
                Remove-Item -LiteralPath 'config/dev.json' -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath 'config/owner.json' -Force -ErrorAction SilentlyContinue
            '''
        }
    }
}
