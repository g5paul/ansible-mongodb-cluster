Example of Deploying a MongoDB (3.6+/4.0+) sharded cluster with Ansible (2.6.3+)
------------------------------------------------------------------------------

- Requires Ansible 2.6.3+ 
- Tested with CentOS 7 
- Tested with Ubuntu 16.04/xenial
- Tested with Debian 9/stretch
- Vagrant support tested with 1.9.8

Example forked from  [ansible mongodb cluster](https://github.com/twoyao/ansible-mongodb-cluster) which was originally re-written from [ansible mongodb example](https://github.com/ansible/ansible-examples/tree/master/mongodb). Example updated with support for mongodb 3.6.7 & 4.0.2, ansible 2.6.3, CentOS 7, Ubuntu 16.04/xenial and Debian 9/stretch.

![Alt text](images/site.png "Site")

The diagram above illustrates the deployment model for a MongoDB cluster deployed by Ansible. 
This deployment model focuses on deploying three shard servers, each having a replica set, 
with the backup replica servers serving as the other two shard primaries. The configuration
servers are co-located with the shards. The mongos servers are best deployed on separate servers. This is the minimum recommended configuration for a production-grade MongoDB deployment. Please note that the playbooks are capable of deploying N node clusters, not limited to three.  Also, all the processes are secured using keyfiles.

#### Prerequisites

- Edit the mongodb/group_vars/all file to reflect the below variables.
  - Set the mongodb version to use via 'mongodb'_version and 'mongodb_version_repo'
  - The default directory for storing data is /data, please do change it if required. Make sure it has sufficient space: 10G is recommended.
- Set a unique mongod_port variable in the inventory file for each MongoDB server.
- If using Vagrant to provision a local cluster edit the 'Vagrantfile' and set distribution to use with 'node.vm.box' and proper vm box memory settings with 'vb.memory'.
-  **Note** that all the processes are secured using [keyfiles](https://docs.mongodb.com/manual/tutorial/enforce-keyfile-access-control-in-existing-replica-set/) which is fine for a dev/testing environment. Production environments should consider using [X.509 Certificates](https://docs.mongodb.com/manual/core/security-x.509/). 
- **Note** that all the processes bind to all IP addresses. Consider [enabling access control](https://docs.mongodb.com/manual/administration/security-checklist/#checklist-auth) and other security measures listed in [Security Checklist](https://docs.mongodb.com/manual/administration/security-checklist/) to prevent unauthorized access.



### Deployment Example
------------------------------------------------------------------------------

The inventory file looks as follows:

		#The site wide list of mongodb servers
		[mongo_servers]
		mongo1 mongod_port=2700
		mongo2 mongod_port=2701
		mongo3 mongod_port=2702
	
		#The list of servers where replication should happen, including the master server.
		[replication_servers]
		mongo3
		mongo1
		mongo2
	
		#The list of mongodb configuration servers, make sure it is 1 or 3
		[mongoc_servers]
		mongo1
		mongo2
		mongo3
	
		#The list of servers where mongos servers would run. 
		[mongos_servers]
		mongos1
		mongos2

Build the site by mongodb playbook using the following command:

		ansible-playbook -i ./mongodb/hosts ./mongodb/site.yml

Run the shard test playbook using the following command:

		ansible-playbook -i ./mongodb/hosts ./mongodb/shard_test.yml

Update the site by mongodb playbook using the following command:

		ansible-playbook -i ./mongodb/hosts  ./mongodb/site.yml --extra-vars "mongo_addusers=false"		

Build the site by **vagrant ansible provision** using the following command:

		vagrant up		

Run the shard test playbook on local vagrant hosts using the following commands:

		ansible-playbook -i ./mongodb/hosts-vagrant  ./mongodb/shard_test.yml

### Verifying the Deployment  
------------------------------------------------------------------------------

Once configuration and deployment has completed we can check replication set availability by connecting to individual primary replication set nodes.
Run `vagrant ssh mongo1 ` to login then exec `mongo localhost/admin -u admin -p 123456` 
and issue the command to query the status of replication set, we should get a similar output.

    mongos> sh.status()
    --- Sharding Status --- 
      sharding version: {
      	"_id" : 1,
      	"minCompatibleVersion" : 5,
      	"currentVersion" : 6,
      	"clusterId" : ObjectId("5b9eee122e24510fabb3eef9")
      }
      shards:
            {  "_id" : "mongo1",  "host" : "mongo1/mongo1:2700,mongo2:2700,mongo3:2700",  "state" : 1 }
            {  "_id" : "mongo2",  "host" : "mongo2/mongo1:2701,mongo2:2701,mongo3:2701",  "state" : 1 }
            {  "_id" : "mongo3",  "host" : "mongo3/mongo1:2702,mongo2:2702,mongo3:2702",  "state" : 1 }
      active mongoses:
            "4.0.2" : 2
      autosplit:
            Currently enabled: yes
      balancer:
            Currently enabled:  yes
            Currently running:  no
            Failed balancer rounds in last 5 attempts:  0
            Migration Results for the last 24 hours: 
                    2 : Success
      databases:
            {  "_id" : "config",  "primary" : "config",  "partitioned" : true }
            {  "_id" : "test",  "primary" : "mongo3",  "partitioned" : true,  "version" : {  "uuid" : UUID("73ad2f76-7fdd-4ce3-9455-5ca43d7c2f54"),  "lastMod" : 1 } }
                    test.messages
                            shard key: { "createTime" : 1 }
                            unique: false
                            balancing: true
                            chunks:
                                    mongo3	1
                            { "createTime" : { "$minKey" : 1 } } -->> { "createTime" : { "$maxKey" : 1 } } on : mongo3 Timestamp(1, 0) 
                    test.user
                            shard key: { "_id" : "hashed" }
                            unique: false
                            balancing: true
                            chunks:
                                    mongo1	2
                                    mongo2	2
                                    mongo3	2
                            { "_id" : { "$minKey" : 1 } } -->> { "_id" : NumberLong("-6148914691236517204") } on : mongo1 Timestamp(3, 2) 
                            { "_id" : NumberLong("-6148914691236517204") } -->> { "_id" : NumberLong("-3074457345618258602") } on : mongo1 Timestamp(3, 3) 
                            { "_id" : NumberLong("-3074457345618258602") } -->> { "_id" : NumberLong(0) } on : mongo2 Timestamp(3, 4) 
                            { "_id" : NumberLong(0) } -->> { "_id" : NumberLong("3074457345618258602") } on : mongo2 Timestamp(3, 5) 
                            { "_id" : NumberLong("3074457345618258602") } -->> { "_id" : NumberLong("6148914691236517204") } on : mongo3 Timestamp(3, 6) 
                            { "_id" : NumberLong("6148914691236517204") } -->> { "_id" : { "$maxKey" : 1 } } on : mongo3 Timestamp(3, 7) 
    


We can check the status of the shards as follows: connect to the mongos service `mongo localhost/test -u admin -p 123456` 
and issue the following command to get the status of the Shards:

    mongos> db.user.find({_id: 1 }).explain()
    {
    	"queryPlanner" : {
    		"mongosPlannerVersion" : 1,
    		"winningPlan" : {
    			"stage" : "SINGLE_SHARD",
    			"shards" : [
    				{
    					"shardName" : "config",
    					"connectionString" : "mongoc/mongo1:7777,mongo2:7777,mongo3:7777",
    					"serverInfo" : {
    						"host" : "mongo1",
    						"port" : 7777,
    						"version" : "4.0.2",
    						"gitVersion" : "fc1573ba18aee42f97a3bb13b67af7d837826b47"
    					},
    					"plannerVersion" : 1,
    					"namespace" : "admin.user",
    					"indexFilterSet" : false,
    					"parsedQuery" : {
    						"_id" : {
    							"$eq" : 1
    						}
    					},
    					"winningPlan" : {
    						"stage" : "EOF"
    					},
    					"rejectedPlans" : [ ]
    				}
    			]
    		}
    	},
    	"ok" : 1,
    	"operationTime" : Timestamp(1537142588, 2),
    	"$clusterTime" : {
    		"clusterTime" : Timestamp(1537142590, 2),
    		"signature" : {
    			"hash" : BinData(0,"8yw7ZCtD9Zx40COhJPH4mtOEemI="),
    			"keyId" : NumberLong("6601975864848547870")
    		}
    	}
    }
    
