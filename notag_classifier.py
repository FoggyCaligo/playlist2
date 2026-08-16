import os
import re

# 1. 설정 변수
TARGET_DIR = r"c:\Users\bigla\Documents\Git\playlist2\pli"
TAG_FILE_PATH = r"c:\Users\bigla\Documents\Git\playlist2\pli_file\tag.txt"
OUTPUT_FILE_PATH = r"c:\Users\bigla\Documents\Git\playlist2\notag.txt"

def load_tags(tag_file_path):
    """태그 파일에서 모든 키워드를 로드합니다."""
    try:
        with open(tag_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        # 줄바꿈 문자   (\n)과 공백을 기준으로 분리하고, 순수한 키워드만 태그 목록으로 만듭니다.
        cleaned_content = re.sub(r'[\s/]+', ' ', content).strip()
        tags = set([word.lower() for word in cleaned_content.split() if word])
        return set(tags)
    except FileNotFoundError:
        print("태그 파일을 찾을 수 없습니다.")
        return set()

def find_untagged_files(target_dir, tags):
    """주어진 디렉토리의 파일 중 태그가 붙지 않은 파일 목록을 반환합니다."""
    untagged_files = []
    print("파일 검색을 시작합니다...")
    
    for filename in os.listdir(target_dir):
        if filename.lower().endswith(".opus"):
            full_path = os.path.join(target_dir, filename)
            # 파일명에서 확장자(.opus)를 제외한 순수 파일명을 가져옴
            name_without_ext = filename[:-5] 
            
            is_tagged = False
            for tag in tags:
                # 파일명의 소문자 버전과 태그를 비교합니다. (대소문자 구분 없이 검색)
                if re.search(re.escape(tag), name_without_ext, re.IGNORECASE):
                    is_tagged = True
                    break
            
            if not is_tagged:
                # 파일명 자체는 태그가 없지만, 전체 경로를 기록할 필요가 있음.
                untagged_files.append(full_path)
    return untagged_files

def write_to_notag_file(paths, output_file):
    """찾아낸 파일 경로들을 notag.txt에 추가합니다."""
    print("\n--- 결과 기록 중 ---")
    if paths:
        with open(output_file, 'a', encoding='utf-8') as f:
            for path in paths:
                f.write(path + '\n')
        print(f"✅ 총 {len(paths)}개의 태그가 없는 파일 경로를 '{output_file}'에 성공적으로 기록했습니다.")
    else:
        print("🎉 모든 파일이 필요한 태그를 가지고 있거나, 처리할 파일을 찾지 못했습니다.")


# --- 실행 로직 시작 ---

# 1. 태그 로드
tags = load_tags(TAG_FILE_PATH)
if not tags:
    exit() # 태그 로드 실패 시 중단

# 2. 태그 없는 파일 검색
untagged_paths = find_untagged_files(TARGET_DIR, tags)

# 3. 결과 기록
write_to_notag_file(untagged_paths, OUTPUT_FILE_PATH)