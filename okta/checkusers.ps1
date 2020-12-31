#################################################################################
# 										                                        #
# This powershell script will check the values of the input file against the    #
# JSON response from Okta /users API request for any match.                     #
# 										                                        #
# Author: rkhanna@propensic.com		                                            #
# Date: October 9, 2020					                                        #
# 										                                        #
# Copyright (c) 2020 Propensic Solutions, LLC.                                  #
# 										                                        #
# This program is free software: you can redistribute it and/or modify it under #
# the terms of the GNU General Public License as published by the Free Software #
# Foundation, either version 3 of the License, or (at your option) any later    #
# version.                                                                      #
# 										                                        #
# This program is distributed in the hope that it will be useful, but WITHOUT   #
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS #
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more        #
# details.                                                                      #
# 										                                        #
# You should have received a copy of the GNU General Public License along with  #
# this program.  If not, see <https://www.gnu.org/licenses/>.                   #
# 										                                        #
#################################################################################

$fileName = 'C:\Temp\file_of_usernames.csv' # set this to match your file with username or userloginname value
$oktaApiToken = '00fmRsWutOgRf0m2VFUonhwjSlnf3jOCULRoDLJmSQ' # set this to your Okta API bearer token
$oktaTenant = 'myokta' # set this to your Okta tenant name, such as "myokta" in "https://myokta.okta.com"
$oktaUsernameAttr = 'login' # set this to the profile attribute you want to compare the usernames in the fileName list against

#### MODIFYING THE FOLLOWING LINES BELOW WITHOUT CONSULTATION MAY RESULT IN UNEXPECTED BEHAVIOR ###

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
    $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()

$file = Import-Csv $fileName
foreach ($line in $file.name) {
    try {
        $response = ''
        $data = ''
        $response = Invoke-WebRequest -Headers @{'Accept' = 'application/json'; 'Authorization' = "SSWS $($oktaApiToken)"} -Method GET -Uri https://$($oktaTenant).okta.com/api/v1/users/$($line) -ContentType application/json
        if ($response.StatusCode -ne 200) {
            Write-Host "$($line) not in Okta"
        } else {
            $data = ConvertFrom-Json $response.content

            foreach ($d in $data) {
                $stat = ''
                $stat = $d.status
                $searchFor = $d.profile.$oktaUsernameAttr
                Write-Host "$($line) found in Okta (with status $($stat))"
                continue
            }
        }
    } catch {
        #$_.Exception.Response.StatusCode.Value__
        Write-Host "$($line) not in Okta"
    }
}
	  

