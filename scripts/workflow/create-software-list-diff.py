import sys
import os
import json

def read_software_file(fname):
    levels = [""]
    groups = {}
    cur_group = None
    cur_tool = None
    line_no = 0

    if os.path.exists(fname):
       with open(fname, "rt", encoding="utf8") as f:
           lines = []
           for line in f:
               line_no += 1
               line = line.rstrip()
               if(not line.strip()): 
                   lines.append(line)
                   continue
               v = line.split(':', 1)
               if(len(v) != 2):
                   raise Exception(f"Invalid line data on line {line_no}")
               prefix = ""
               for c in line:
                   if not(c in [' ', "\t"]): break
                   prefix += c
               line = line.lstrip()
               if(len(prefix) >= len(levels[-1])):
                   if(not prefix.startswith(levels[-1])):
                       #print(f"Prefix: '{prefix}'")
                       #print(levels)
                       #print(groups)
                       raise Exception(f"Invalid ident on line {line_no}")
                   new_level = len(prefix) > len(levels[-1])
                   if(new_level):
                       levels.append(prefix)
               else:    
                   while(len(prefix) < len(levels[-1])):
                       levels.pop()
                   if(prefix != levels[-1]):
                       raise Exception(f"Invalid ident on line {line_no}")

               k,v = line.split(':', 1)
               v = v.lstrip()
               k = k.rstrip()
               if(len(levels) == 1):
                   cur_group = {}
                   if(k.lower() != "group"): Exception(f"Invalid key on line {line_no}: {k}")
                   groups[v] = cur_group
               elif(len(levels) == 2):
                   cur_tool = {}
                   if(k.lower() != "item"): Exception(f"Invalid key on line {line_no}: {k}")
                   cur_group[v] = cur_tool
               elif(len(levels) == 3):
                   cur_tool[k] = v
               else:
                   raise Exception(f"Invalid ident on line {line_no}")
    return groups

def get_diff(soft1, soft2):
    diff = []
    def add_diff(operation, group, item, prev, new):
        diff.append((operation, group, item, prev, new))
    for new_k, new in soft2.items():
        old = soft1[new_k] if (new_k in soft1) else None
        if(old is None) or (json.dumps(old) != json.dumps(new)):
            op = 'add' if (old is None) else 'mod'
            add_diff(op, new_k, new, old, new)
    for old_k, old in soft1.items():
        new = soft2[new_k] if (old_k in soft2) else None
        if(new is None):
            add_diff('del', old_k, old, old, new)
    return diff

def get_software_diff(soft1, soft2):
    diff = get_diff(soft1, soft2)
    #print('DBG0', diff)
    res_diff = []
    for d in diff:
       (op, group, item, prev, new) = d
       if(op == 'mod'):
           diff_items = get_diff(prev, new)
           for di in diff_items:
               (op, subgroup, subitem, _, _) = di
               res_diff.append((op, group, subgroup, subitem, item))
       else:
           for it_name, it in item.items():
               res_diff.append((op, group, it_name, it, item))
    return res_diff

prev_software_file = sys.argv[1]
new_software_file = sys.argv[2]

prev_software = read_software_file(prev_software_file)
new_software = read_software_file(new_software_file)
diff = get_software_diff(prev_software, new_software)
#print('DBG2', diff)
if(diff):
    print("Tools changelog:\n")
    #op_map = {"add": "+", "del": "-", "mod": "*"}
    op_map_w = {"add": "added version", "del": "removed", "mod": "updated to version"}
    for op, group, tool, info, group_item in diff:
        res = op_map_w[op]
        if(op != "del"):
            ver = info['Version']
            if('Url' in info): 
                ver = f"[{ver}]({info['Url']})"
            res += f" {ver}"

        print(f"- {group if ((group == tool) and (len(group_item) < 2)) else (group + ' (' + tool + ')')} {res}")
