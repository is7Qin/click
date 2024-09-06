#!/bin/bash

# 定义目录路径数组
dir_paths=("/rclone/backup/vp" "/rclone/backup/allopt")

# 计算30天前的日期
date_threshold=$(date -d "-30 days" +%s)

# 遍历每个目录路径
for dir_path in "${dir_paths[@]}"; do
    echo "Processing directory: $dir_path"

    # 获取所有年月的数组
    year_month_arr=($(find "$dir_path" -type f -printf "%TY-%Tm\n" | sort -u))

    # 遍历年月数组
    for year_month in "${year_month_arr[@]}"; do
        # 查找同年月的文件
        same_year_month_files=$(find "$dir_path" -type f -printf "%TY-%Tm %p %Ts\n" | grep "^$year_month")

        # 找到同年月中最后创建的文件
        last_created_file=$(echo "$same_year_month_files" | sort -k1,1 -k3,3nr | head -n1 | awk '{print $2}')

        # 遍历同年月的文件
        echo "$same_year_month_files" | while read -r line; do
            file=$(echo "$line" | awk '{print $2}')
            file_date=$(stat -c %Y "$file")

            # 如果当前文件不是同年月中最后创建的文件且超过30天，则删除
            if [[ "$file" != "$last_created_file" && "$file_date" -lt "$date_threshold" ]]; then
                rm -f "$file"
                echo "Deleted: $file"
            fi
        done
    done
done
