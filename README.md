This project is used to test nebula

#1. modules 

    README.md : doc
    build:      build nebula code to package
    cases:      store case
    conf:       store test hosts info 
                store nebula service conf
                test tool conf
    perftest:   perftest workflow
    setup:      setup tool


#2. perftest
    A setup: 
      chose machines and setup os,ip 
      add user vesoft  make dirs for test and  config ssh password free login in machines
      add data in the location 
      install mysql and config perftest db 
      This repo`s setup work now is done, you can ignore it 
      If you change machine you should  redo it and add conf in this repo
      
    B Chose one machine as control machine
      Download this repo (this repo use 192.168.15.4)
      git clone xxx
      cd nebula-test-platform
      sh setup/setup.sh
      This step is done , if you change machine you should redo it 

    C How to run 
      cd nebula-test-platform/perftest

      // install perftest tools 
      S1.  ansible-playbook  -i ../conf/perftest_conf/hosts  playbook_prepare.yml
 
      // build and install nebula service 
      S2.  ansible-playbook  -i ../conf/perftest_conf/hosts playbook_build_install_nebula.yaml
 
      // run perftest
      S3.  ansible-playbook  -i ../conf/perftest_conf/hosts playbook_perftest.yaml
           this repo use 2 machines to run perftest          

      // stop service and clean env, this step if used  must redo S1,S2 
      S4. ansible-playbook  -i ../conf/perftest_conf/hosts playbook_stop_clean.yml
   
   D If you want to run daily ,you can add it to machine  crontab 
   
   E Add perf case based on ldbc

     [case file] : cases/perftest/case.json
 
     [add info to cases/perftest/case.json,data example]:
     {"casename":"case1_1_step_0050_thread","perftest_nGQL":"go 1 step from replace over knows","perftest_num_threads":"25","perftest_duration":"7"}     

   F Others
     Now the machine`s system monitor
     http://192.168.15.4:3000/d/9CWBz0bik/1-node-exporter-for-prometheus-dashboard-cn-v20201010?orgId=1
     
   G PerfDashboard
     http://192.168.8.6:3000/collection/root admin@xxx.com/admin123  
    
 
