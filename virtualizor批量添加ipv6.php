<?php

    require_once('/usr/local/virtualizor/sdk/admin.php');

    $key =  '';                         //key
    $pass = '';                         //key pass
    $ip = '';               // Server IP
    $ip_pid = '2';                      //IPPool ID
    $ip_file = '1.txt';                 //IPlist File

    $file = fopen($ip_file, "r");
    $ip_list = array();
    // 逐行读取文件内容
    while (($line = fgets($file)) !== false) {
            $parts = explode(":", trim($line));

        // 输出处理后的结果
            $ip_list[] = $parts;
    }
    fclose($file);
    //print_r($ip_list);

    $admin = new Virtualizor_Admin_API($ip, $key, $pass);

    $post = array();
    $post['iptype'] = 6;            //4 for ipv4 & 6 for ipv6
    $post['ips6'] = $ip_list;
    $post['macs'] = array('');
    $post['ipv6_1'] = '';
    $post['ipv6_2'] = '';
    $post['ipv6_3'] = '';
    $post['ipv6_4'] = '';
    $post['ipv6_5'] = '';
    $post['ipv6_6'] = '';
    $post['ipv6_num'] = '';
    $post['ippid'] = $ip_pid;
    $post['ip_serid'] = '0';

    $output = $admin->addips($post);

    print_r(json_encode($output));
