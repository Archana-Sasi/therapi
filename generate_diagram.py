import base64
import urllib.request
import json
import sys

def main():
    input_file = 'c:\\MAD\\Therap_app\\use_case_diagram.mmd'
    output_file = 'c:\\MAD\\Therap_app\\use_case_diagram.png'
    
    with open(input_file, 'r', encoding='utf-8') as f:
        diagram = f.read()
        
    state = {
        "code": diagram,
        "mermaid": {"theme": "default"}
    }
    
    json_str = json.dumps(state)
    b64_str = base64.b64encode(json_str.encode('utf-8')).decode('utf-8')
    
    url = f"https://mermaid.ink/img/{b64_str}"
    print(f"Fetching from mermaid.ink...")
    
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open(output_file, 'wb') as out_file:
            data = response.read()
            out_file.write(data)
        print(f"Image generated successfully at {output_file}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
