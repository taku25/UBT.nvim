-- UBT.nvim: build config presets and user config merge
local M = {}


local defaults = {
  -- 標準プリセット
  presets = {
    {
      name = "Win64Debug",
      Platform = "Win64",
      IsEditor = false,
      Configuration = "Debug",
    },
    {
      name = "Win64DebugGame",
      Platform = "Win64",
      IsEditor = false,
      Configuration = "DebugGame",
    },
    {
      name = "Win64Develop",
      Platform = "Win64",
      IsEditor = false,
      Configuration = "Development",
    },
    {
      name = "Win64Shipping",
      Platform = "Win64",
      IsEditor = false,
      Configuration = "Shipping",
    },
    {
      name = "Win64Test",
      Platform = "Win64",
      IsEditor = false,
      Configuration = "Test",
    },
    {
      name = "Win64DebugWithEditor",
      Platform = "Win64",
      IsEditor = true,
      Configuration = "Debug",
    },
    {
      name = "Win64DebugGameWithEditor",
      Platform = "Win64",
      IsEditor = true,
      Configuration = "DebugGame",
    },
    {
      name = "Win64DevelopWithEditor",
      Platform = "Win64",
      IsEditor = true,
      Configuration = "Development",
    },
  },

  -- default label
  preset_target = "Win64DevelopWithEditor",
  -- default lintertype
  lint_type = "Default",
  -- default shell
  shell = "cmd",
  -- engine_path
  engine_path = nil,

  --NONE = dont show
  --ALL
  --WARN
  --ERROR.
  notify_level = "NONE",
  progress_level = "ALL",
  message_level = "ERROR",
  -- M.message_level = "ERROR"
  -- override fidget setting
  enable_override_fidget = true,

  enable_log_file = true,
  -- override fidget setting
  log_file_name = "diagnostics.log",
  progress_file_name = "progress.log",
}

M.active_config = {}
M.user_config = {}


-- @param base_presets table: デフォルトとなるプリセットのリスト
-- @param new_presets table: 追加または上書きしたいプリセットのリスト
-- @return table: マージされた新しいプリセットのリスト
local function merge_presets(base_presets, new_presets)
  if not new_presets or #new_presets == 0 then
    return base_presets
  end

  -- プリセットを名前で索引できる一時的なテーブルを作成
  local by_name = {}
  for _, p in ipairs(base_presets) do
    by_name[p.name] = p
  end
  
  -- 新しいプリセットで、追加または上書きを行う
  for _, p in ipairs(new_presets) do
    by_name[p.name] = p
  end
  
  -- 索引テーブルから、最終的なリストを再構築
  local merged = {}
  for _, p in pairs(by_name) do
    table.insert(merged, p)
  end
  
  return merged
end

--- Looks for and loads a `.ubtrc` file from the project root.
-- @param root_dir string: The project root directory to search in.
-- @return table: The decoded JSON content, or an empty table if not found or invalid.
local function load_project_config(root_dir)
  -- 1. ファイルパスを構築
  -- vim.fs.join() は、OSに関係なく、正しいパス区切り文字を使ってくれる便利な関数
  local config_file_path = root_dir .. "/".. ".ubtrc"

  -- 2. ファイルが存在するかどうかをチェック
  -- vim.fn.filereadable() は、ファイルが存在し、読み取り可能なら1を返す
  if vim.fn.filereadable(config_file_path) ~= 1 then
    -- ファイルが見つからなければ、静かに空のテーブルを返す
    return {}, nil
  end

  -- 3. ファイルの内容を読み込む
  -- pcallで、読み込みエラーが発生してもクラッシュしないようにする
  local read_ok, file_content_lines = pcall(vim.fn.readfile, config_file_path)
  if not read_ok or not file_content_lines then
    return nil ,"UBT: Failed to read .ubtrc file: " .. tostring(file_content_lines)
  end

  local json_string = table.concat(file_content_lines, "\n")
  
  -- 4. JSON文字列をLuaのテーブルにデコードする
  -- pcallで、JSONの構文エラーがあってもクラッシュしないようにする
  local decode_ok, decoded_json = pcall(vim.fn.json_decode, json_string)
  if not decode_ok or type(decoded_json) ~= "table" then
    return nil, "UBT: Invalid JSON in .ubtrc file: " .. tostring(decoded_json)
  end

  -- 5. 成功すれば、デコードされたテーブルを返す
  return decoded_json, nil
end


--- 複数の設定ソースをマージし、M.active_configを更新する
-- @param root_dir string: 現在のプロジェクトルート
function M.load_config(root_dir)
  local new_config = vim.deepcopy(defaults)
  
  -- 1. ユーザーのグローバル設定で上書き
  for k, v in pairs(user_config) do
    if k == "presets" then
      -- プリセットは、単純な上書きではなく、マージする
      new_config.presets = merge_presets(new_config.presets, v)
    else
      new_config[k] = v
    end
  end

  -- 2. プロジェクト固有の .ubtrc で、さらに上書き
  local project_conf, err = load_project_config(root_dir)
  if not err and project_conf then
    for k, v in pairs(project_conf) do
      if k == "presets" then
        -- ここでも、単純な上書きではなく、マージする
        new_config.presets = merge_presets(new_config.presets, v)
      else
        new_config[k] = v
      end
    end
  end

  M.active_config = new_config
end

--- プラグインの初期化時に、ユーザーから呼ばれる唯一の関数
function M.setup(opts)
  -- ユーザー設定を保存
  user_config = opts or {}
  
  M.load_config(vim.fn.getcwd())
end

-- 初期ロード時に、とりあえずデフォルト値で埋めておく
M.active_config = vim.deepcopy(defaults)

return M
