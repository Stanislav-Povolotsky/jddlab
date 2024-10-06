# Author: https://github.com/Stanislav-Povolotsky/
# Supported formats:
# - GitHub:
#   https://github.com/<author>/<repo>[/releases/tag/<tag>]
#   https://github.com/CalebFenton/simplify
#   https://github.com/CalebFenton/simplify/releases/tag/v1.3.0
# - Google Maven
#   https://maven.google.com/web/index.html#<package>:<artifact>:[<version>]
#   https://maven.google.com/web/index.html#com.android.tools.smali:smali
#   https://maven.google.com/web/index.html#com.android.tools.smali:smali:3.0.8
import sys
import re
import requests
import json
import traceback
import xml.etree.ElementTree as ET

def get_release_info(url, tag = 'latest'):
    release_info = None
    if url.startswith("https://github.com/"):
        release_info = get_release_info_github(url, tag = tag)
    #elif url.startswith("https://mvnrepository.com/"):
    #    release_info = get_release_info_mvnrepository(url, tag = tag)
    elif url.startswith("https://maven.google.com/"):
        release_info = get_release_info_google_maven(url, tag = tag)
    elif url.startswith("https://www.jetbrains.com/"):
        release_info = get_release_info_jetbrains(url, tag = tag)
    if(not release_info):
        raise Exception("Unsupported project url")
    return release_info

def get_release_info_github(url, tag = 'latest'):
    m = re.match(R'^https://github.com/([^/]+/[^/]+)', url)
    release_info = None
    if m:
        project_path = m.group(1)
        if('/releases/tag/' in url):
            m = re.match(R'^https://github.com/([^/]+/[^/]+)/releases/tag/([^/?]+)', url)
            tag = m.group(2)

        release_info = {'project-url': f"https://github.com/{project_path}"}
        try:
            url = f'https://api.github.com/repos/{project_path}/releases/{tag if (tag.lower() == "latest") else "tags/" + tag}'
            print(url)
            response = requests.get(url).json()
            if("status" in response) and (response['status'] != '200') and ("message" in response):
                raise Exception(response['message'])
        except Exception as e:
            raise Exception(f"Project {url} tag '{tag}' request error: {e}")
        release_info['url'] = response["html_url"]
        release_info['tag'] = response["tag_name"]
        release_info['version'] = response["name"]
        assets = response["assets"] if ("assets" in response) else []
        release_info['assets'] = [{'name': a['name'], 'url': a["browser_download_url"]} for a in assets]
    else:
        raise Exception(f"Unsupported url format: {url}")
    return release_info

def get_release_info_google_maven(url, tag = 'latest'):
    # https://maven.google.com/web/index.html#<package>:<artifact>:[<version>]
    m = re.match(R'^https://maven.google.com/[^#]+#([^:]+):([^:]+)(:([^:]+))?$', url)
    release_info = None
    if m:
        package_name = m.group(1)
        artifact = m.group(2)
        opt_version = m.group(4)
        if(opt_version):
            tag = opt_version

        if(tag.lower() == 'latest'):
            try:
                response = requests.get(f'https://dl.google.com/dl/android/maven2/{package_name.replace(".","/")}/group-index.xml').text
                root = ET.fromstring(response)
                found = False
                for artifact_node in root:
                    cur_artifact = artifact_node.tag
                    versions = artifact_node.get('versions')
                    versions = versions.split(",") if versions else []
                    if(cur_artifact == artifact):
                        tag = versions[-1]
                        found = True
                        break
                if(not found): 
                    raise Exception("No such artifact {artifact}")
            except Exception as e:
                raise Exception(f"Project '{url}' tag '{tag}' request error: {e}")

        
        release_info = {'project-url': f"https://maven.google.com/web/index.html#{package_name}:{artifact}:{tag}"}
        try:
            url = f'https://dl.google.com/android/maven2/{package_name.replace(".","/")}/{artifact}/{tag}/artifact-metadata.json'
            response = requests.get(url).json()
            if("status" in response) and (response['status'] != '200') and ("message" in response):
                raise Exception(response['message'])
        except Exception as e:
            raise Exception(f"Project {url} tag '{tag}' request error: {e}")
        release_info['url'] = release_info['project-url']
        release_info['tag'] = tag
        release_info['version'] = f"{artifact} {tag}"
        assets = response["artifacts"] if ("artifacts" in response) else []
        # {"name":"smali-3.0.8-javadoc.jar","tag":"javadoc"}
        release_info['assets'] = [{'name': a['name'], 'url': 
            f"https://dl.google.com/android/maven2/{package_name.replace('.','/')}/{artifact}/{tag}/{a['name']}"} 
            for a in assets]
    else:
        raise Exception(f"Unsupported url format: {url}")
    return release_info

"""
def get_release_info_mvnrepository(url, tag = 'latest'):
    m = re.match(R'^https://mvnrepository.com/artifact/(([^/]+)/([^/]+))(/([^/]+))?', url)
    release_info = None
    headers = {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
    }
    if m:
        project_path = m.group(1)
        project_group = m.group(2)
        project_name = m.group(3)
        if m.group(5) is not None:
            tag = m.group(5)

        project_url = f"https://mvnrepository.com/artifact/{project_path}"
        release_info = {'project-url': project_url}
        if(tag == 'latest'):
            try:
              response = requests.get(project_url, headers=headers).text
              m = re.find('class="vbtn release">([^<]+)</a>')
              tag = m.group(1)
            except Exception as e:
              raise Exception(f"Project {url} tag '{tag}' request error: {e}")

        assets = []
        try:
          home_url = f'https://mvnrepository.com/artifact/{project_path}/{tag}'
          response = requests.get(home_url, headers=headers).text
          txt_open = '>Files</th><td>'
          txt_close = '>View All</a></td></tr>'
          print(response)
          p1 = response.index(txt_open) if (txt_open in response) else None
          p2 = response.index(txt_close) if (txt_close in response) else None
          if(p1 and p2):
            files_txt = response[txt_open:txt_close]
            allm = re.findall(R'<a class="vbtn" href="([^"]+)">', files_txt)
            for m in allm:
              url = m.group(1)
              fname = url[url.rindex('/') + 1:] if('/' in url) else url
              assets.append({'name': fname, 'url': url})
        except Exception as e:
          #print(traceback.format_exc())
          raise Exception(f"Project {url} tag '{tag}' request error: {e}")

        release_info['url'] = home_url
        release_info['tag'] = tag
        release_info['version'] = tag
        release_info['assets'] = assets
    else:
        raise Exception(f"Unsupported url format: {url}")
    return release_info
"""

def parse_jetbrains_releases():
    try:
      response = requests.get('https://www.jetbrains.com/intellij-repository/releases/').text
    except Exception as e:
      raise Exception(f"Jetbrains releases is not available: {e}")

    p = re.compile("<h2>([^<]+)</h2>[\r\n\s]+<table>", flags=re.DOTALL)
    pitem = re.compile("<tr>\s*<td>([^<]+)</td>\s*<td>([^<]*)</td>\s*<td>([^<]*)</td>\s*<td>([^\n]*)\s*</td>\s*</tr>", flags=re.DOTALL)
    partifact = re.compile(R'<a href="([^"]+)">([^<]+)</a>')
    
    parsed_groups = {}            
    for m in p.finditer(response):
        group = m.group(1)
        current_group = []
        table = response[m.end() : response.index('</table>', m.end())]
        if('<tbody>' in table): table = table[table.index('<tbody>'):]
        for item in pitem.finditer(table):
            version = item.group(1)
            date = item.group(2)
            artifacts = item.group(4)
            #print(group, version, artifacts)
            cur_artifacts = []
            cur_ver_info = {'version': version, 'data': date, 'artifacts': cur_artifacts}
            for a in partifact.finditer(artifacts):
                url = a.group(1)
                fname = a.group(2)
                cur_artifacts.append({'name': fname, 'url': url})
                #print(group, version, fname, url)
            current_group.append(cur_ver_info)
    
        parsed_groups[group] = current_group
    return parsed_groups

def get_release_info_jetbrains(url, tag = 'latest'):
    # Examples:
    # https://www.jetbrains.com/:com.jetbrains.intellij.java
    # https://www.jetbrains.com/:com.jetbrains.intellij.java/java-decompiler.jar
    # https://www.jetbrains.com/:com.jetbrains.intellij.java/java-decompiler.jar:latest
    # https://www.jetbrains.com/:com.jetbrains.intellij.java/java-decompiler.jar:242.22855.74
    m = re.match(R'^https://www.jetbrains.com/[^:]*:([^:/]+)(/([^:]+))?(:([^:]+))?$', url)
    release_info = None

    if m:
        project_group = m.group(1)
        project_name = m.group(3)
        if m.group(5) is not None:
            tag = m.group(5)

        try:
            releases = parse_jetbrains_releases()
        except Exception as e:
          raise Exception(f"Project {url} tag '{tag}' request error: {e}")

        if(project_group not in releases):
            raise Exception(f"Project {project_group} not found in jetbrains releases")
        use_project = releases[project_group]
        if(project_name):
            use_project = [p for p in use_project if len([a for a in p['artifacts'] if a['name'] == project_name])]
        if(not use_project):
            raise Exception(f"Project {project_group} has no versions")

        if(tag.lower() == 'latest'): tag = use_project[0]['version']
        use_version = [p for p in use_project if p['version'] == tag]
        if(not use_version):
            raise Exception(f"Project {project_group} has no such version '{tag}'")
        use_version = use_version[0]

        project_url = f"https://www.jetbrains.com/intellij-repository/releases/#{project_group}"
        release_info = {'project-url': project_url}
        release_info['url'] = project_url
        release_info['tag'] = tag
        release_info['version'] = tag
        release_info['assets'] = use_version['artifacts']

        if(project_name):
            release_info['assets'] = [a for a in release_info['assets'] if a['name'] == project_name]

    else:
        raise Exception(f"Unsupported url format: {url}")
    return release_info


def filter_assets(assets, filter_asset_name_re = None):
    if(filter_asset_name_re):
        flt = filter_asset_name_re
        if(not flt.startswith('^')): flt = ".*" + flt
        if(not flt.endswith('$')): flt = flt + ".*"
        try:
            flt = re.compile(flt)
        except Exception as e:
            raise Exception(f"Invalid asset filtration regex: {filter_asset_name_re}")
        assets = [a for a in assets if flt.match(a['name'])]
    return assets

if __name__ == '__main__':
    try:
        import argparse
        parser = argparse.ArgumentParser(description="Get information about project release (on GitHub)")
        parser.add_argument('url', help='Project URL')
        parser.add_argument('-t', '--tag', default='latest', help='The tag to use (default: latest)')
        parser.add_argument('-fan', '--filter-asset-name', default=None, help='Regex to filter by asset file name')
        parser.add_argument('-of', '--output-format', default='txt4lines', choices=['json', 'txt4lines'], help='Output format')
        parser.add_argument('-o', '--output-file', default=None, help='Output file path')
        args = parser.parse_args()

        url = args.url
        tag = args.tag
        filter_asset_name_re = args.filter_asset_name
        fmt = args.output_format
        output_file = args.output_file
        res = get_release_info(url, tag = tag)
        res['assets'] = filter_assets(res['assets'], filter_asset_name_re = filter_asset_name_re)

        def open_output():
            return sys.stdout if(output_file is None) else open(output_file, "wt", encoding="utf8")

        if(fmt == 'json'):
            print(json.dumps(res, indent = 4, ensure_ascii = False), file=open_output())
        elif(fmt == 'txt4lines'):
            f = res['assets']
            if(not f):
                raise Exception("No matching assets found")
            lines = [res['version'], res['url'], f[0]['name'], f[0]['url']]
            print("\n".join(lines), file = open_output())

    except Exception as e:
        print(f"Fatal error: {e}", file=sys.stderr)
        print(traceback.format_exc())
        sys.exit(1)